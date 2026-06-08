import Foundation

struct ExportShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

enum ConversationExport {
    static func shareItem(for conversation: Conversation) -> ExportShareItem? {
        guard let url = try? ExportFormatter.writeTemporaryMarkdownFile(for: conversation) else {
            return nil
        }
        return ExportShareItem(url: url)
    }
}
