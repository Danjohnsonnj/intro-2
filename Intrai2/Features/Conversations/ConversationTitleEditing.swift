import Foundation
import SwiftData

enum ConversationTitleEditing {
    static func applyManualRename(
        to conversation: Conversation,
        title: String,
        in modelContext: ModelContext
    ) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        conversation.title = trimmed
        conversation.titleLocked = true
        conversation.updatedAt = .now
        try? modelContext.save()
    }
}
