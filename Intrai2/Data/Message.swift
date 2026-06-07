import Foundation
import SwiftData

@Model
final class Message {
    var id: UUID
    var role: String
    var content: String
    var createdAt: Date
    /// Monotonic position in the thread — user/assistant pairs get sequential indices on send.
    var orderIndex: Int
    var conversation: Conversation?

    init(
        id: UUID = UUID(),
        role: String,
        content: String,
        createdAt: Date = .now,
        orderIndex: Int = 0,
        conversation: Conversation? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.orderIndex = orderIndex
        self.conversation = conversation
    }
}
