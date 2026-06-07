import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class ChatViewModel {
    var composeText = ""
    private(set) var isGenerating = false
    private(set) var generationError: String?
    private(set) var streamingMessageID: UUID?

    let conversationID: UUID

    private let modelContext: ModelContext
    private let generationService = ChatGenerationService()
    private var generationTask: Task<Void, Never>?

    init(conversationID: UUID, modelContext: ModelContext) {
        self.conversationID = conversationID
        self.modelContext = modelContext
    }

    func sortedMessages(for conversation: Conversation) -> [Message] {
        migrateLegacyOrderIndicesIfNeeded(in: conversation)
        return conversation.messages.sorted { lhs, rhs in
            if lhs.orderIndex != rhs.orderIndex {
                return lhs.orderIndex < rhs.orderIndex
            }
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }
            return Self.roleSortRank(lhs.role) < Self.roleSortRank(rhs.role)
        }
    }

    var canSend: Bool {
        !composeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating
    }

    func send(isModelReady: Bool, in conversation: Conversation) {
        let trimmed = composeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isGenerating, isModelReady else { return }

        composeText = ""
        generationError = nil

        let now = Date.now
        let nextOrderIndex = (conversation.messages.map(\.orderIndex).max() ?? -1) + 1

        let userMessage = Message(
            role: ChatPromptMessage.roleUser,
            content: trimmed,
            createdAt: now,
            orderIndex: nextOrderIndex
        )
        userMessage.conversation = conversation
        conversation.messages.append(userMessage)
        touchConversation(conversation, at: now)

        let assistantMessage = Message(
            role: ChatPromptMessage.roleAssistant,
            content: "",
            createdAt: now.addingTimeInterval(0.001),
            orderIndex: nextOrderIndex + 1
        )
        assistantMessage.conversation = conversation
        conversation.messages.append(assistantMessage)
        touchConversation(conversation, at: now)
        saveContext()

        streamingMessageID = assistantMessage.id
        isGenerating = true

        let promptMessages = promptMessages(for: conversation)
        generationTask = Task { [weak self] in
            guard let self else { return }
            await self.runGeneration(
                promptMessages: promptMessages,
                assistantMessage: assistantMessage,
                conversation: conversation
            )
        }
    }

    func cancelGeneration() {
        generationTask?.cancel()
    }

    private func runGeneration(
        promptMessages: [ChatPromptMessage],
        assistantMessage: Message,
        conversation: Conversation
    ) async {
        defer {
            isGenerating = false
            streamingMessageID = nil
            generationTask = nil
        }

        do {
            for try await chunk in generationService.stream(messages: promptMessages) {
                if Task.isCancelled { break }
                assistantMessage.content += chunk
                touchConversation(conversation)
                saveContext()
            }
            touchConversation(conversation)
            saveContext()
        } catch is CancellationError {
            touchConversation(conversation)
            saveContext()
        } catch {
            if !Task.isCancelled {
                generationError = error.localizedDescription
                if assistantMessage.content.isEmpty {
                    assistantMessage.content = error.localizedDescription
                }
                touchConversation(conversation)
                saveContext()
            }
        }
    }

    private func promptMessages(for conversation: Conversation) -> [ChatPromptMessage] {
        let history = sortedMessages(for: conversation)
            .filter { message in
                let role = message.role
                guard role == ChatPromptMessage.roleUser || role == ChatPromptMessage.roleAssistant else {
                    return false
                }
                if message.id == streamingMessageID {
                    return false
                }
                let trimmed = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                return !trimmed.isEmpty
            }
            .map { message in
                ChatPromptMessage(role: message.role, content: message.content)
            }

        return ChatPromptBuilder.transcript(history: history)
    }

    private func touchConversation(_ conversation: Conversation, at date: Date = .now) {
        conversation.updatedAt = date
    }

    private func migrateLegacyOrderIndicesIfNeeded(in conversation: Conversation) {
        let messages = conversation.messages
        guard messages.count > 1 else { return }

        let assignedIndices = Set(messages.map(\.orderIndex))
        let needsMigration = messages.allSatisfy { $0.orderIndex == 0 }
            || assignedIndices.count < messages.count
        guard needsMigration else { return }

        let sorted = messages.sorted { lhs, rhs in
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }
            return Self.roleSortRank(lhs.role) < Self.roleSortRank(rhs.role)
        }
        for (index, message) in sorted.enumerated() {
            message.orderIndex = index
        }
        saveContext()
    }

    private static func roleSortRank(_ role: String) -> Int {
        role == ChatPromptMessage.roleUser ? 0 : 1
    }

    private func saveContext() {
        try? modelContext.save()
    }
}
