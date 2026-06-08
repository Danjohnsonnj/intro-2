import Foundation

enum ChatGenerationEvent: Sendable {
    case historyTrimmed
    case chunk(String)
}

struct ChatService: Sendable {
    private let trimmer: any HistoryTrimmer
    private let augmentation: any ContextAugmentation
    private let generationService: ChatGenerationService

    init(
        trimmer: any HistoryTrimmer = SlidingWindowTrimmer(),
        augmentation: any ContextAugmentation = NoOpContextAugmentation(),
        generationService: ChatGenerationService = ChatGenerationService()
    ) {
        self.trimmer = trimmer
        self.augmentation = augmentation
        self.generationService = generationService
    }

    func generate(
        history: [ChatPromptMessage],
        systemPrompt: String = ChatPromptBuilder.defaultSystemPrompt,
        options: GenerationOptions = GenerationOptions()
    ) -> AsyncThrowingStream<ChatGenerationEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await SharedLlamaInference.shared.withSession(unloadOnExit: false) { session in
                        let augmented = try await augmentation.augment(
                            messages: history,
                            trigger: .send
                        )
                        let trimOutcome = try trimmer.trim(
                            history: augmented,
                            systemPrompt: systemPrompt,
                            bridge: session.bridge,
                            generationMaxTokens: options.maxTokens
                        )
                        let messages = ChatPromptBuilder.transcript(
                            systemPrompt: systemPrompt,
                            history: trimOutcome.history
                        )

                        if trimOutcome.didTrim {
                            continuation.yield(.historyTrimmed)
                        }

                        for try await chunk in generationService.stream(
                            messages: messages,
                            options: options,
                            bridge: session.bridge
                        ) {
                            continuation.yield(.chunk(chunk))
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
                Task {
                    await SharedLlamaInference.shared.cancelActiveGeneration()
                }
            }
        }
    }
}
