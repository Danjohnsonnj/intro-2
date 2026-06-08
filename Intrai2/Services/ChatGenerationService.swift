import Foundation

struct ChatGenerationService: Sendable {
    private let coalesceInterval: Duration = .milliseconds(16)

    func stream(
        messages: [ChatPromptMessage],
        options: GenerationOptions = GenerationOptions()
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await SharedLlamaInference.shared.withSession(unloadOnExit: false) { session in
                        for try await chunk in stream(
                            messages: messages,
                            options: options,
                            bridge: session.bridge
                        ) {
                            continuation.yield(chunk)
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

    func stream(
        messages: [ChatPromptMessage],
        options: GenerationOptions,
        bridge: LlamaCppBridge
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await pumpStream(
                        messages: messages,
                        options: options,
                        bridge: bridge,
                        continuation: continuation
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
                bridge.cancelGeneration()
            }
        }
    }

    private func pumpStream(
        messages: [ChatPromptMessage],
        options: GenerationOptions,
        bridge: LlamaCppBridge,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let prompt = try bridge.formatChatPrompt(
            messages: messages,
            addGenerationPrompt: true
        )
        try bridge.startRawPrompt(prompt, options: options)

        var pending = ""
        var lastFlush = ContinuousClock.now

        while true {
            if Task.isCancelled {
                bridge.cancelGeneration()
                break
            }

            guard let chunk = try bridge.nextTokenChunk() else {
                break
            }
            if Task.isCancelled {
                bridge.cancelGeneration()
                break
            }
            if chunk.isEmpty { continue }

            pending += chunk
            let elapsed = lastFlush.duration(to: .now)
            if elapsed >= coalesceInterval {
                continuation.yield(pending)
                pending = ""
                lastFlush = .now
            }
        }

        if !pending.isEmpty {
            continuation.yield(pending)
        }
    }
}
