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
    private(set) var showTrimNotice = false

    let conversationID: UUID

    private let modelContext: ModelContext
    private let chatService = ChatService()
    private let titleGenerationService = TitleGenerationService()
    private var generationTask: Task<Void, Never>?

    private var pendingSendID: UUID?
    private var pendingSendText: String?
    private var pendingUserMessageID: UUID?
    private var pendingAssistantMessageID: UUID?
    private var pendingPreviousUpdatedAt: Date?

    init(conversationID: UUID, modelContext: ModelContext) {
        self.conversationID = conversationID
        self.modelContext = modelContext
    }

    var isSettling: Bool {
        pendingSendID != nil && generationTask == nil
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

    /// Phase 1: insert in-memory placeholders; no persist, no inference.
    func prepareSend(text: String, in conversation: Conversation) -> UUID? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSettling else { return nil }

        generationError = nil
        showTrimNotice = false

        let sendID = UUID()
        pendingSendID = sendID
        pendingSendText = trimmed
        pendingPreviousUpdatedAt = conversation.updatedAt

        let now = Date.now
        let nextOrderIndex = (conversation.messages.map(\.orderIndex).max() ?? -1) + 1

        let userMessage = Message(
            role: ChatPromptMessage.roleUser,
            content: trimmed,
            createdAt: now,
            orderIndex: nextOrderIndex
        )
        let assistantMessage = Message(
            role: ChatPromptMessage.roleAssistant,
            content: "",
            createdAt: now.addingTimeInterval(0.001),
            orderIndex: nextOrderIndex + 1
        )

        pendingUserMessageID = userMessage.id
        pendingAssistantMessageID = assistantMessage.id

        composeText = ""
        isGenerating = true
        streamingMessageID = assistantMessage.id
        userMessage.conversation = conversation
        assistantMessage.conversation = conversation
        conversation.messages.append(userMessage)
        conversation.messages.append(assistantMessage)
        touchConversation(conversation, at: now)

        return sendID
    }

    /// Phase 2: persist and start inference after UI settle completes.
    func startPreparedInference(pendingSendID sendID: UUID, in conversation: Conversation) {
        guard pendingSendID == sendID,
              let assistantMessageID = pendingAssistantMessageID,
              let assistantMessage = conversation.messages.first(where: { $0.id == assistantMessageID })
        else { return }

        clearPendingSendState()

        let history = chatHistory(for: conversation)
        saveContext()

        generationTask = Task { [weak self] in
            guard let self else { return }
            await self.runGeneration(
                history: history,
                assistantMessage: assistantMessage,
                conversation: conversation
            )
        }
    }

    /// Roll back a prepared send that never reached inference (settle-window Stop / navigate away).
    func cancelPreparedSend(pendingSendID sendID: UUID, in conversation: Conversation) {
        guard pendingSendID == sendID else { return }

        if let userID = pendingUserMessageID {
            conversation.messages.removeAll { $0.id == userID }
        }
        if let assistantID = pendingAssistantMessageID {
            conversation.messages.removeAll { $0.id == assistantID }
        }
        if let previousUpdatedAt = pendingPreviousUpdatedAt {
            conversation.updatedAt = previousUpdatedAt
        }

        isGenerating = false
        streamingMessageID = nil
        if let pendingSendText {
            composeText = pendingSendText
        }
        clearPendingSendState()
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

    private func clearPendingSendState() {
        pendingSendID = nil
        pendingSendText = nil
        pendingUserMessageID = nil
        pendingAssistantMessageID = nil
        pendingPreviousUpdatedAt = nil
    }

    private func runGeneration(
        history: [ChatPromptMessage],
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
            for try await event in chatService.generate(
                history: history,
                systemPrompt: SettingsStore.resolvedSystemPrompt,
                options: SettingsStore.generationOptions()
            ) {
                if Task.isCancelled { break }
                switch event {
                case .historyTrimmed:
                    showTrimNotice = true
                case .chunk(let chunk):
                    assistantMessage.content += chunk
                    touchConversation(conversation)
                }
            }
            touchConversation(conversation)
            scheduleAutoTitleIfNeeded(for: conversation)
        } catch is CancellationError {
            touchConversation(conversation)
            scheduleAutoTitleIfNeeded(for: conversation)
        } catch {
            if !Task.isCancelled {
                generationError = error.localizedDescription
                if assistantMessage.content.isEmpty {
                    conversation.messages.removeAll { $0.id == assistantMessage.id }
                }
                touchConversation(conversation)
            }
        }
    }

    private func chatHistory(for conversation: Conversation) -> [ChatPromptMessage] {
        sortedMessages(for: conversation)
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
        if !isSettling {
            saveContext()
        }
    }

    private static func roleSortRank(_ role: String) -> Int {
        role == ChatPromptMessage.roleUser ? 0 : 1
    }

    private func saveContext() {
        try? modelContext.save()
    }

    private func scheduleAutoTitleIfNeeded(for conversation: Conversation) {
        guard shouldAutoGenerateTitle(for: conversation) else { return }
        guard let firstUserMessage = firstUserMessageContent(in: conversation) else { return }

        Task {
            guard let title = await titleGenerationService.generateTitle(from: firstUserMessage) else {
                return
            }
            guard shouldAutoGenerateTitle(for: conversation) else { return }
            conversation.title = title
            touchConversation(conversation)
            saveContext()
        }
    }

    private func shouldAutoGenerateTitle(for conversation: Conversation) -> Bool {
        guard !conversation.titleLocked else { return false }
        guard conversation.title == Conversation.defaultTitle else { return false }

        let messages = sortedMessages(for: conversation)
        guard messages.count == 2 else { return false }
        guard messages[0].role == ChatPromptMessage.roleUser else { return false }
        guard messages[1].role == ChatPromptMessage.roleAssistant else { return false }

        let assistantContent = messages[1].content.trimmingCharacters(in: .whitespacesAndNewlines)
        return !assistantContent.isEmpty
    }

    private func firstUserMessageContent(in conversation: Conversation) -> String? {
        let messages = sortedMessages(for: conversation)
        guard let first = messages.first, first.role == ChatPromptMessage.roleUser else {
            return nil
        }
        let trimmed = first.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
