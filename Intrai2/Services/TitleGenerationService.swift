import Foundation

struct TitleGenerationService: Sendable {
    private let generationService = ChatGenerationService()

    private static let maxInputCharacters = 500
    private static let titleSystemPrompt =
        "You generate short conversation titles. "
        + "Reply with only a title of 3 to 6 words. "
        + "No quotes, no trailing punctuation, no explanation."

    private static let generationOptions = GenerationOptions(maxTokens: 24, temperature: 0.3)

    func generateTitle(from firstUserMessage: String) async -> String? {
        let trimmed = firstUserMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let capped = String(trimmed.prefix(Self.maxInputCharacters))
        let messages = [
            ChatPromptMessage(role: ChatPromptMessage.roleSystem, content: Self.titleSystemPrompt),
            ChatPromptMessage(role: ChatPromptMessage.roleUser, content: capped),
        ]

        var raw = ""
        do {
            try await SharedLlamaInference.shared.withSession(unloadOnExit: true) { session in
                for try await chunk in generationService.stream(
                    messages: messages,
                    options: Self.generationOptions,
                    bridge: session.bridge
                ) {
                    if Task.isCancelled { return }
                    raw += chunk
                }
            }
        } catch {
            return nil
        }

        return Self.sanitizeTitle(raw)
    }

    private static func sanitizeTitle(_ raw: String) -> String? {
        var title = raw
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if title.hasPrefix("\""), title.hasSuffix("\""), title.count >= 2 {
            title = String(title.dropFirst().dropLast())
        } else if title.hasPrefix("'"), title.hasSuffix("'"), title.count >= 2 {
            title = String(title.dropFirst().dropLast())
        }

        title = title.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }

        let words = title.split(whereSeparator: \.isWhitespace)
        guard !words.isEmpty else { return nil }

        let cappedWords = words.prefix(6)
        return cappedWords.joined(separator: " ")
    }
}
