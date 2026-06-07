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
        !composeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func send(isModelReady: Bool, in conversation: Conversation) {
        let trimmed = composeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, isModelReady else { return }

        if isGenerating {
            let pending = trimmed
            composeText = ""
            Task {
                await stopAndWaitForCompletion()
                beginSend(text: pending, in: conversation)
            }
            return
        }

        composeText = ""
        beginSend(text: trimmed, in: conversation)
    }

    func stopGeneration() {
        generationTask?.cancel()
        Task {
            await SharedLlamaInference.shared.cancelActiveGeneration()
        }
    }

    /// Awaits in-flight decode cancellation — used for cancel-then-send and view teardown.
    func stopAndWaitForCompletion() async {
        guard let task = generationTask else { return }
        task.cancel()
        await SharedLlamaInference.shared.cancelActiveGeneration()
        await task.value
    }

    private func beginSend(text: String, in conversation: Conversation) {
        generationError = nil

        let now = Date.now
        let nextOrderIndex = (conversation.messages.map(\.orderIndex).max() ?? -1) + 1

        let userMessage = Message(
            role: ChatPromptMessage.roleUser,
            content: text,
            createdAt: now,
            orderIndex: nextOrderIndex
        )
        let assistantMessage = Message(
            role: ChatPromptMessage.roleAssistant,
            content: "",
            createdAt: now.addingTimeInterval(0.001),
            orderIndex: nextOrderIndex + 1
        )

        // UI-first: flip generating state and attach in-memory messages before persistence/inference.
        isGenerating = true
        streamingMessageID = assistantMessage.id
        userMessage.conversation = conversation
        assistantMessage.conversation = conversation
        conversation.messages.append(userMessage)
        conversation.messages.append(assistantMessage)
        touchConversation(conversation, at: now)

        generationTask = Task { [weak self] in
            guard let self else { return }
            await Task.yield()

            let promptMessages = self.promptMessages(for: conversation)
            self.saveContext()

            await self.runGeneration(
                promptMessages: promptMessages,
                assistantMessage: assistantMessage,
                conversation: conversation
            )
        }
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
            saveContext()
        }

        do {
            for try await chunk in generationService.stream(messages: promptMessages) {
                if Task.isCancelled { break }
                assistantMessage.content += chunk
                touchConversation(conversation)
            }
            touchConversation(conversation)
        } catch is CancellationError {
            touchConversation(conversation)
        } catch {
            if !Task.isCancelled {
                generationError = error.localizedDescription
                if assistantMessage.content.isEmpty {
                    assistantMessage.content = error.localizedDescription
                }
                touchConversation(conversation)
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
