import Foundation
import SwiftData

@Model
final class Message {
    var id: UUID
    var role: String
    var content: String
    var createdAt: Date
    var conversation: Conversation?

    init(
        id: UUID = UUID(),
        role: String,
        content: String,
        createdAt: Date = .now,
        conversation: Conversation? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.conversation = conversation
    }
}
