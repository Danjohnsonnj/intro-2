import Foundation
import SwiftData

@Model
final class Conversation {
    var id: UUID
    var title: String
    var titleLocked: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Message.conversation)
    var messages: [Message]

    init(
        id: UUID = UUID(),
        title: String = "New conversation",
        titleLocked: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.titleLocked = titleLocked
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = []
    }
}
