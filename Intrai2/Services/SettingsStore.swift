import Foundation

/// UserDefaults persistence for global inference settings (Slice 6).
enum SettingsStore {
    nonisolated static let allowedContextLengths = [2048, 4096, 8192]
    nonisolated static let defaultContextLength = 4096
    nonisolated static let defaultCreativity = 0.7
    nonisolated static let minCreativity = 0.1
    nonisolated static let maxCreativity = 1.5
    nonisolated static let creativityStep = 0.1

    private nonisolated static let systemPromptKey = "intrai2.systemPrompt"
    private nonisolated static let nCtxKey = "intrai2.nCtx"
    private nonisolated static let temperatureKey = "intrai2.temperature"

    /// User-facing label: Creativity. Stored as sampler temperature under the hood.
    nonisolated static var creativity: Double {
        guard UserDefaults.standard.object(forKey: temperatureKey) != nil else {
            return defaultCreativity
        }
        let stored = UserDefaults.standard.double(forKey: temperatureKey)
        return clampCreativity(stored)
    }

    /// Alias for inference pipeline (`GenerationOptions.temperature`).
    nonisolated static var temperature: Double { creativity }

    nonisolated static var resolvedSystemPrompt: String {
        let stored = UserDefaults.standard.string(forKey: systemPromptKey)
        let trimmed = stored?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            return ChatPromptBuilder.defaultSystemPrompt
        }
        return trimmed
    }

    nonisolated static var nCtx: UInt32 {
        UInt32(clamping: clampContextLength(storedContextLength))
    }

    nonisolated static func save(
        systemPrompt: String,
        nCtx: Int,
        creativity: Double
    ) {
        let trimmed = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: systemPromptKey)
        } else {
            UserDefaults.standard.set(trimmed, forKey: systemPromptKey)
        }
        UserDefaults.standard.set(clampContextLength(nCtx), forKey: nCtxKey)
        UserDefaults.standard.set(clampCreativity(creativity), forKey: temperatureKey)
        notifySettingsDidChange()
    }

    nonisolated static func generationOptions(maxTokens: Int = 512) -> GenerationOptions {
        GenerationOptions(maxTokens: maxTokens, temperature: creativity)
    }

    nonisolated static func clampContextLength(_ value: Int) -> Int {
        guard allowedContextLengths.contains(value) else {
            return allowedContextLengths.min(by: { abs($0 - value) < abs($1 - value) })
                ?? defaultContextLength
        }
        return value
    }

    nonisolated static func clampCreativity(_ value: Double) -> Double {
        let stepped = (value / creativityStep).rounded() * creativityStep
        return max(minCreativity, min(maxCreativity, stepped))
    }

    nonisolated private static var storedContextLength: Int {
        let stored = UserDefaults.standard.object(forKey: nCtxKey) as? Int ?? defaultContextLength
        return clampContextLength(stored)
    }

    nonisolated private static func notifySettingsDidChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .intraiInferenceSettingsDidChange, object: nil)
        }
    }
}
