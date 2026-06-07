import Foundation
import Darwin

#if canImport(llama)
import llama

nonisolated final class LlamaCppRuntime: @unchecked Sendable, LlamaCppBridge {
    struct RuntimeConfig: Sendable {
        let contextWindow: UInt32
        let promptSlackTokens: Int
        let physicalBatchSize: UInt32

        static let chatDefault = RuntimeConfig(contextWindow: 4096, promptSlackTokens: 64, physicalBatchSize: 1024)

        init(contextWindow: UInt32, promptSlackTokens: Int, physicalBatchSize: UInt32 = 1024) {
            self.contextWindow = contextWindow
            self.promptSlackTokens = promptSlackTokens
            self.physicalBatchSize = physicalBatchSize
        }
    }

    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var shouldCancel = false
    private let config: RuntimeConfig
    private var contextLimitTokens: Int = Int(RuntimeConfig.chatDefault.contextWindow)

    private var generationSampler: UnsafeMutablePointer<llama_sampler>?
    private var promptTokenBuffer: UnsafeMutablePointer<llama_token>?
    private var decSingleToken: UnsafeMutablePointer<llama_token>?

    private var nPos: Int = 0
    private var nPrompt: Int = 0
    private var nPredict: Int = 0
    private var lastSampledToken: llama_token = 0
    private var hasActiveGeneration = false
    private var backendSlotHeld = false

    private static let abortTrampoline: @convention(c) (UnsafeMutableRawPointer?) -> Bool = { data in
        guard let data else { return false }
        let runtime = Unmanaged<LlamaCppRuntime>.fromOpaque(data).takeUnretainedValue()
        return runtime.shouldCancel
    }

    init(config: RuntimeConfig = .chatDefault) {
        self.config = config
        self.contextLimitTokens = Int(config.contextWindow)
    }

    deinit {
        releaseGenerationState(freeContext: true)
        Self.releaseBackendSlot(&backendSlotHeld)
    }

    func loadModel(path: String) throws {
        releaseGenerationState(freeContext: true)
        shouldCancel = false

        try validateModelFile(at: path)
        Self.acquireBackendSlot(&backendSlotHeld)

        var modelParams = llama_model_default_params()
#if targetEnvironment(simulator)
        modelParams.n_gpu_layers = 0
#else
        modelParams.n_gpu_layers = -1
#endif

        guard let loadedModel = llama_model_load_from_file(path, modelParams) else {
            throw LlamaInferenceError.modelLoadFailed(
                "llama.cpp could not load the model. The file may be corrupt or unsupported."
            )
        }

        if llama_model_has_encoder(loadedModel) {
            llama_model_free(loadedModel)
            throw LlamaInferenceError.modelLoadFailed(
                "Encoder–decoder models are not supported. Use a decoder-only GGUF."
            )
        }

        var contextParams = llama_context_default_params()
        let trainCtx = Int(llama_model_n_ctx_train(loadedModel))
        let requested = config.contextWindow
        let effectiveCtx: UInt32
        if trainCtx > 0 {
            effectiveCtx = min(requested, UInt32(clamping: trainCtx))
        } else {
            effectiveCtx = requested
        }
        contextParams.n_ctx = effectiveCtx
        contextParams.n_batch = effectiveCtx
        contextParams.n_ubatch = config.physicalBatchSize
        contextParams.n_seq_max = 1
        contextParams.flash_attn_type = LLAMA_FLASH_ATTN_TYPE_AUTO
        contextParams.offload_kqv = true
        contextParams.kv_unified = false

        let nThreads = max(1, min(8, ProcessInfo.processInfo.processorCount - 2))
        contextParams.n_threads = Int32(nThreads)
        contextParams.n_threads_batch = Int32(nThreads)

        guard let loadedContext = llama_init_from_model(loadedModel, contextParams) else {
            llama_model_free(loadedModel)
            throw LlamaInferenceError.modelLoadFailed("Unable to initialize llama context.")
        }

        model = loadedModel
        context = loadedContext
        contextLimitTokens = Int(contextParams.n_ctx)
    }

    func unloadModel() {
        releaseGenerationState(freeContext: true)
    }

    func countTemplatedUserPromptTokens(_ user: String) throws -> Int {
        guard let mdl = model else { throw LlamaInferenceError.modelNotLoaded }
        let formatted = makeFormattedChatPrompt(userText: user, model: mdl)
        let vocab = llama_model_get_vocab(mdl)
        let nTok = formatted.withCString { cstr in
            Int32(-llama_tokenize(vocab, cstr, Int32(strlen(cstr)), nil, 0, false, true))
        }
        guard nTok > 0 else {
            throw LlamaInferenceError.generationFailed("Failed to tokenize the prompt.")
        }
        return Int(nTok)
    }

    func maxTemplatedPromptTokensForGeneration(_ generationMaxTokens: Int) -> Int {
        let contextLimit = contextLimitTokens
        let slack = config.promptSlackTokens
        let generationBudget = max(1, generationMaxTokens)
        return max(1, min(contextLimit - slack, contextLimit - generationBudget - 1))
    }

    func formatChatPrompt(messages: [ChatPromptMessage], addGenerationPrompt: Bool) throws -> String {
        guard model != nil else { throw LlamaInferenceError.modelNotLoaded }
        guard !messages.isEmpty else {
            throw LlamaInferenceError.generationFailed("No messages to format.")
        }

        guard let mdl = model else { throw LlamaInferenceError.modelNotLoaded }
        let template: String
        if let templatePointer = llama_model_chat_template(mdl, nil) {
            template = String(cString: templatePointer)
        } else {
            template = ""
        }

        if template.isEmpty {
            return ChatPromptBuilder.fallbackChatML(
                messages: messages,
                addGenerationPrompt: addGenerationPrompt
            )
        }

        if let formatted = ChatPromptBuilder.applyTemplate(
            messages: messages,
            template: template,
            addGenerationPrompt: addGenerationPrompt
        ) {
            return formatted
        }

        return ChatPromptBuilder.fallbackChatML(
            messages: messages,
            addGenerationPrompt: addGenerationPrompt
        )
    }

    func startTemplatedUserPrompt(_ user: String, options: GenerationOptions) throws {
        guard let mdl = model else { throw LlamaInferenceError.modelNotLoaded }
        let formatted = makeFormattedChatPrompt(userText: user, model: mdl)
        try startTokenizingPrompt(formatted, options: options)
    }

    func startRawPrompt(_ fullChatPrompt: String, options: GenerationOptions) throws {
        guard model != nil else { throw LlamaInferenceError.modelNotLoaded }
        try startTokenizingPrompt(fullChatPrompt, options: options)
    }

    func nextTokenChunk() throws -> String? {
        guard let ctx = context,
              let mdl = model,
              let smpl = generationSampler,
              let promptBuffer = promptTokenBuffer,
              let singleTokenBuffer = decSingleToken
        else {
            if model != nil, context != nil, !hasActiveGeneration { return nil }
            throw LlamaInferenceError.modelNotLoaded
        }
        if shouldCancel {
            releaseGenerationState(freeContext: false)
            return nil
        }
        guard hasActiveGeneration else { return nil }

        let vocab = llama_model_get_vocab(mdl)

        if nPos < nPrompt {
            let remaining = nPrompt - nPos
            let chunkSize = min(Int(config.physicalBatchSize), remaining)
            let batch = llama_batch_get_one(promptBuffer.advanced(by: nPos), Int32(chunkSize))

            if nPos + chunkSize >= nPrompt + nPredict {
                releaseGenerationState(freeContext: false)
                return nil
            }

            let decodeResult = llama_decode(ctx, batch)
            if decodeResult < 0 {
                releaseGenerationState(freeContext: false)
                throw LlamaInferenceError.generationFailed("Inference error during decode (code \(decodeResult)).")
            }
            if decodeResult == 1 {
                releaseGenerationState(freeContext: false)
                throw LlamaInferenceError.contextLimitReached("Context full — try shorter content.")
            }
            nPos += chunkSize

            if shouldCancel {
                releaseGenerationState(freeContext: false)
                return nil
            }

            if nPos < nPrompt {
                return ""
            }
        } else {
            singleTokenBuffer.pointee = lastSampledToken
            let batch = llama_batch_get_one(singleTokenBuffer, 1)

            if nPos + 1 >= nPrompt + nPredict {
                releaseGenerationState(freeContext: false)
                return nil
            }

            let decodeResult = llama_decode(ctx, batch)
            if decodeResult < 0 {
                releaseGenerationState(freeContext: false)
                throw LlamaInferenceError.generationFailed("Inference error during decode (code \(decodeResult)).")
            }
            if decodeResult == 1 {
                releaseGenerationState(freeContext: false)
                throw LlamaInferenceError.contextLimitReached("Context full — try shorter content.")
            }
            nPos += 1
        }

        let newToken = llama_sampler_sample(smpl, ctx, -1)
        if llama_vocab_is_eog(vocab, newToken) {
            releaseGenerationState(freeContext: false)
            return nil
        }

        var piece = [CChar](repeating: 0, count: 512)
        var pieceLength = llama_token_to_piece(vocab, newToken, &piece, Int32(piece.count), 0, true)
        if pieceLength < 0 {
            let needed = -Int(pieceLength)
            piece = [CChar](repeating: 0, count: needed + 1)
            pieceLength = llama_token_to_piece(vocab, newToken, &piece, Int32(piece.count), 0, true)
        }
        lastSampledToken = newToken

        guard pieceLength > 0 else { return "" }
        let copyLength = min(Int(pieceLength), piece.count)
        if copyLength < piece.count {
            piece[copyLength] = 0
        } else {
            piece[copyLength - 1] = 0
        }
        return String(cString: piece)
    }

    func cancelGeneration() {
        shouldCancel = true
    }

    private func validateModelFile(at path: String) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path) else {
            throw LlamaInferenceError.modelLoadFailed("Model file not found on disk.")
        }
        guard fileManager.isReadableFile(atPath: path) else {
            throw LlamaInferenceError.modelLoadFailed("Model file is not readable.")
        }
        let attributes = try fileManager.attributesOfItem(atPath: path)
        let size = attributes[.size] as? UInt64 ?? 0
        guard size > 0 else {
            throw LlamaInferenceError.modelLoadFailed("Model file is empty.")
        }
    }

    private static var backendUsers = 0
    private static let backendLock = NSLock()

    private static func acquireBackendSlot(_ held: inout Bool) {
        backendLock.lock()
        defer { backendLock.unlock() }
        if !held {
            if backendUsers == 0 {
                llama_backend_init()
            }
            backendUsers += 1
            held = true
        }
    }

    private static func releaseBackendSlot(_ held: inout Bool) {
        backendLock.lock()
        defer { backendLock.unlock() }
        guard held else { return }
        backendUsers = max(0, backendUsers - 1)
        if backendUsers == 0 {
            llama_backend_free()
        }
        held = false
    }

    private func makeFormattedChatPrompt(userText: String, model: OpaquePointer) -> String {
        guard let templatePointer = llama_model_chat_template(model, nil) else {
            return Self.fallbackChatML(userText)
        }
        let template = String(cString: templatePointer)
        if template.isEmpty {
            return Self.fallbackChatML(userText)
        }

        return "user".withCString { userRole in
            userText.withCString { userContent in
                var message = llama_chat_message(role: userRole, content: userContent)
                var output = [CChar](repeating: 0, count: 256_000)
                let written = withUnsafePointer(to: &message) { messagePointer in
                    template.withCString { templateCString in
                        Int(llama_chat_apply_template(
                            templateCString,
                            messagePointer,
                            1,
                            true,
                            &output,
                            Int32(output.count)
                        ))
                    }
                }
                if written < 0 || written >= output.count {
                    return Self.fallbackChatML(userText)
                }
                output[written] = 0
                guard let formatted = String(validatingUTF8: output) else {
                    return Self.fallbackChatML(userText)
                }
                if formatted.isEmpty { return Self.fallbackChatML(userText) }
                return formatted
            }
        }
    }

    private static func fallbackChatML(_ userText: String) -> String {
        let endMarker = "<|" + "im_end|>"
        return "<|im_start|>user\n\(userText)\(endMarker)\n<|im_start|>assistant\n"
    }

    private func startTokenizingPrompt(_ formatted: String, options: GenerationOptions) throws {
        guard let ctx = context, let mdl = model else {
            throw LlamaInferenceError.modelNotLoaded
        }
        shouldCancel = false
        releaseGenerationState(freeContext: false)

        if llama_model_has_encoder(mdl) {
            throw LlamaInferenceError.generationFailed(
                "Encoder–decoder models are not supported. Use a decoder-only GGUF."
            )
        }

        let vocab = llama_model_get_vocab(mdl)
        let tokenCount = formatted.withCString { cstr in
            Int32(-llama_tokenize(vocab, cstr, Int32(strlen(cstr)), nil, 0, false, true))
        }
        guard tokenCount > 0 else {
            throw LlamaInferenceError.generationFailed("Failed to tokenize the prompt.")
        }
        let promptLimit = max(1, contextLimitTokens - config.promptSlackTokens)
        if Int(tokenCount) > promptLimit {
            throw LlamaInferenceError.contextLimitReached(
                "The prompt is too long for the current context (\(contextLimitTokens) tokens)."
            )
        }

        let buffer = UnsafeMutablePointer<llama_token>.allocate(capacity: Int(tokenCount))
        let written = formatted.withCString { cstr in
            llama_tokenize(vocab, cstr, Int32(strlen(cstr)), buffer, tokenCount, false, true)
        }
        guard written >= 0 else {
            buffer.deallocate()
            throw LlamaInferenceError.generationFailed("Tokenization failed.")
        }

        let memory = llama_get_memory(ctx)
        llama_memory_clear(memory, true)

        decSingleToken = UnsafeMutablePointer<llama_token>.allocate(capacity: 1)

        var samplerParams = llama_sampler_chain_default_params()
        samplerParams.no_perf = true
        guard let sampler = llama_sampler_chain_init(samplerParams) else {
            buffer.deallocate()
            decSingleToken?.deallocate()
            decSingleToken = nil
            throw LlamaInferenceError.generationFailed("Failed to create sampler.")
        }
        let temperature = max(0.0, min(2.0, options.temperature))
        if temperature < 0.0001 {
            llama_sampler_chain_add(sampler, llama_sampler_init_greedy())
        } else {
            llama_sampler_chain_add(sampler, llama_sampler_init_top_k(40))
            llama_sampler_chain_add(sampler, llama_sampler_init_top_p(0.95, 1))
            llama_sampler_chain_add(sampler, llama_sampler_init_temp(Float(temperature)))
            llama_sampler_chain_add(sampler, llama_sampler_init_dist(LLAMA_DEFAULT_SEED))
        }
        generationSampler = sampler

        let contextLimit = contextLimitTokens
        let capacityForNew = max(0, contextLimit - Int(tokenCount) - 1)
        nPredict = min(max(0, options.maxTokens), capacityForNew)
        nPrompt = Int(tokenCount)
        promptTokenBuffer = buffer
        nPos = 0
        lastSampledToken = 0
        hasActiveGeneration = nPredict > 0

        if nPredict == 0 {
            releaseGenerationState(freeContext: false)
            throw LlamaInferenceError.contextLimitReached("No room left in context for a reply.")
        }

        llama_set_abort_callback(ctx, Self.abortTrampoline, Unmanaged.passUnretained(self).toOpaque())
    }

    private func releaseGenerationState(freeContext: Bool) {
        if let ctx = context {
            llama_set_abort_callback(ctx, nil, nil)
        }
        if let sampler = generationSampler {
            llama_sampler_free(sampler)
            generationSampler = nil
        }
        promptTokenBuffer?.deallocate()
        promptTokenBuffer = nil
        decSingleToken?.deallocate()
        decSingleToken = nil
        nPos = 0
        nPrompt = 0
        nPredict = 0
        lastSampledToken = 0
        hasActiveGeneration = false

        guard freeContext else { return }
        if let ctx = context {
            llama_free(ctx)
            context = nil
        }
        if let mdl = model {
            llama_model_free(mdl)
            model = nil
        }
    }
}

#else

nonisolated final class LlamaCppRuntime: @unchecked Sendable, LlamaCppBridge {
    init() {}

    func loadModel(path: String) throws {
        _ = path
        throw LlamaInferenceError.modelLoadFailed(
            "llama.xcframework is not linked. Run scripts/setup-llama-xcframework.sh and rebuild."
        )
    }

    func unloadModel() {}

    func countTemplatedUserPromptTokens(_ user: String) throws -> Int {
        _ = user
        throw LlamaInferenceError.modelNotLoaded
    }

    func maxTemplatedPromptTokensForGeneration(_ generationMaxTokens: Int) -> Int {
        let contextLimit = 4096
        let slack = 64
        let generationBudget = max(1, generationMaxTokens)
        return max(1, min(contextLimit - slack, contextLimit - generationBudget - 1))
    }

    func formatChatPrompt(messages: [ChatPromptMessage], addGenerationPrompt: Bool) throws -> String {
        _ = messages
        _ = addGenerationPrompt
        throw LlamaInferenceError.modelNotLoaded
    }

    func startTemplatedUserPrompt(_ user: String, options: GenerationOptions) throws {
        _ = user
        _ = options
        throw LlamaInferenceError.modelNotLoaded
    }

    func startRawPrompt(_ fullChatPrompt: String, options: GenerationOptions) throws {
        _ = fullChatPrompt
        _ = options
        throw LlamaInferenceError.modelNotLoaded
    }

    func nextTokenChunk() throws -> String? { nil }

    func cancelGeneration() {}
}

#endif
