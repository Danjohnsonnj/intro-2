import Foundation

struct HistoryTrimOutcome: Sendable, Equatable {
    let history: [ChatPromptMessage]
    let didTrim: Bool
}

protocol HistoryTrimmer: Sendable {
    func trim(
        history: [ChatPromptMessage],
        systemPrompt: String,
        bridge: LlamaCppBridge,
        generationMaxTokens: Int
    ) throws -> HistoryTrimOutcome
}

struct SlidingWindowTrimmer: HistoryTrimmer {
    func trim(
        history: [ChatPromptMessage],
        systemPrompt: String,
        bridge: LlamaCppBridge,
        generationMaxTokens: Int
    ) throws -> HistoryTrimOutcome {
        var trimmedHistory = history
        let tokenBudget = bridge.maxTemplatedPromptTokensForGeneration(generationMaxTokens)
        var didTrim = false

        while try promptTokenCount(
            history: trimmedHistory,
            systemPrompt: systemPrompt,
            bridge: bridge
        ) > tokenBudget {
            guard dropOldestPair(from: &trimmedHistory) else { break }
            didTrim = true
        }

        if try promptTokenCount(
            history: trimmedHistory,
            systemPrompt: systemPrompt,
            bridge: bridge
        ) > tokenBudget {
            throw LlamaInferenceError.contextLimitReached(
                "This conversation is too long to fit in context, even after trimming earlier turns."
            )
        }

        return HistoryTrimOutcome(history: trimmedHistory, didTrim: didTrim)
    }

    private func promptTokenCount(
        history: [ChatPromptMessage],
        systemPrompt: String,
        bridge: LlamaCppBridge
    ) throws -> Int {
        let messages = ChatPromptBuilder.transcript(systemPrompt: systemPrompt, history: history)
        return try bridge.countChatPromptTokens(messages: messages, addGenerationPrompt: true)
    }

    private func dropOldestPair(from history: inout [ChatPromptMessage]) -> Bool {
        let userCount = history.count { $0.role == ChatPromptMessage.roleUser }
        guard userCount > 1 else { return false }

        guard let userIndex = history.firstIndex(where: { $0.role == ChatPromptMessage.roleUser }) else {
            history.removeFirst()
            return true
        }

        history.remove(at: userIndex)
        if userIndex < history.count, history[userIndex].role == ChatPromptMessage.roleAssistant {
            history.remove(at: userIndex)
        }
        return true
    }
}
