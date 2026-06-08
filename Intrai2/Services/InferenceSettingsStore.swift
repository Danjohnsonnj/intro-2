import Foundation
import Observation

@Observable
@MainActor
final class InferenceSettingsStore {
    var systemPromptDraft = SettingsStore.resolvedSystemPrompt
    var contextLength = SettingsStore.clampContextLength(Int(SettingsStore.nCtx))
    var creativity = SettingsStore.creativity

    private(set) var lastActionError: String?

    var systemPromptHint: String {
        let characters = systemPromptDraft.count
        let estimatedTokens = max(1, Int((Double(characters) / 4.0).rounded()))
        return "~\(estimatedTokens) tokens · \(characters) characters"
    }

    var contextLengthLabel: String {
        String(contextLength)
    }

    var creativityLabel: String {
        String(format: "%.1f", creativity)
    }

    var canDecrementContextLength: Bool {
        guard let index = SettingsStore.allowedContextLengths.firstIndex(of: contextLength) else {
            return false
        }
        return index > 0
    }

    var canIncrementContextLength: Bool {
        guard let index = SettingsStore.allowedContextLengths.firstIndex(of: contextLength) else {
            return false
        }
        return index < SettingsStore.allowedContextLengths.count - 1
    }

    func syncFromStore() {
        systemPromptDraft = SettingsStore.resolvedSystemPrompt
        contextLength = SettingsStore.clampContextLength(Int(SettingsStore.nCtx))
        creativity = SettingsStore.creativity
    }

    func decrementContextLength(modelStore: ModelStore) {
        guard canDecrementContextLength,
              let index = SettingsStore.allowedContextLengths.firstIndex(of: contextLength) else {
            return
        }
        contextLength = SettingsStore.allowedContextLengths[index - 1]
        Task { await persistContextLength(modelStore: modelStore) }
    }

    func incrementContextLength(modelStore: ModelStore) {
        guard canIncrementContextLength,
              let index = SettingsStore.allowedContextLengths.firstIndex(of: contextLength) else {
            return
        }
        contextLength = SettingsStore.allowedContextLengths[index + 1]
        Task { await persistContextLength(modelStore: modelStore) }
    }

    func setCreativity(_ value: Double) {
        creativity = SettingsStore.clampCreativity(value)
        persistCreativity()
    }

    func commitSystemPrompt() {
        persistSystemPrompt()
    }

    private func persistCreativity() {
        lastActionError = nil
        SettingsStore.save(
            systemPrompt: systemPromptDraft,
            nCtx: contextLength,
            creativity: creativity
        )
    }

    private func persistSystemPrompt() {
        lastActionError = nil
        SettingsStore.save(
            systemPrompt: systemPromptDraft,
            nCtx: contextLength,
            creativity: creativity
        )
        systemPromptDraft = SettingsStore.resolvedSystemPrompt
    }

    private func persistContextLength(modelStore: ModelStore) async {
        lastActionError = nil
        SettingsStore.save(
            systemPrompt: systemPromptDraft,
            nCtx: contextLength,
            creativity: creativity
        )

        guard ModelManager.hasReadableSelection else { return }

        await SharedLlamaInference.shared.reloadForSettingsChange()
        await modelStore.warmLoadIfNeeded()
        if let actionError = modelStore.lastActionError {
            lastActionError = actionError
        }
    }
}
