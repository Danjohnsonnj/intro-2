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
                        let prompt = try session.bridge.formatChatPrompt(
                            messages: messages,
                            addGenerationPrompt: true
                        )
                        try session.bridge.startRawPrompt(prompt, options: options)

                        var pending = ""
                        var lastFlush = ContinuousClock.now

                        while true {
                            if Task.isCancelled {
                                session.bridge.cancelGeneration()
                                break
                            }

                            guard let chunk = try session.bridge.nextTokenChunk() else {
                                break
                            }
                            if Task.isCancelled {
                                session.bridge.cancelGeneration()
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
