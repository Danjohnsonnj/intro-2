import Foundation

enum ExportFormatter {
    static func markdown(for conversation: Conversation) -> String {
        let title = conversation.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let header = title.isEmpty ? "# New conversation" : "# \(title)"

        var lines = [header, ""]
        for message in sortedMessages(in: conversation) {
            let roleLabel = message.role == ChatPromptMessage.roleUser ? "User" : "Assistant"
            lines.append("## \(roleLabel)")
            lines.append("")
            if !message.content.isEmpty {
                lines.append(message.content)
                lines.append("")
            }
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
    }

    static func fileName(for conversation: Conversation) -> String {
        let sanitized = conversation.title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let base = sanitized.isEmpty ? "conversation" : sanitized
        return "\(base).md"
    }

    static func writeTemporaryMarkdownFile(for conversation: Conversation) throws -> URL {
        let markdown = markdown(for: conversation)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName(for: conversation))
        try markdown.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func sortedMessages(in conversation: Conversation) -> [Message] {
        conversation.messages.sorted { lhs, rhs in
            if lhs.orderIndex != rhs.orderIndex {
                return lhs.orderIndex < rhs.orderIndex
            }
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }
            return roleSortRank(lhs.role) < roleSortRank(rhs.role)
        }
    }

    private static func roleSortRank(_ role: String) -> Int {
        role == ChatPromptMessage.roleUser ? 0 : 1
    }
}
