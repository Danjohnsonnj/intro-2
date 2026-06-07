import SwiftData
import SwiftUI

struct ChatThreadView: View {
    let conversationID: UUID

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(ModelStore.self) private var modelStore
    @Query private var matches: [Conversation]

    @State private var viewModel: ChatViewModel?

    private let bottomScrollAnchorID = "chat-thread-bottom"

    init(conversationID: UUID) {
        self.conversationID = conversationID
        _matches = Query(filter: #Predicate<Conversation> { $0.id == conversationID })
    }

    private var conversation: Conversation? {
        matches.first
    }

    var body: some View {
        Group {
            if let conversation {
                chatContent(conversation: conversation)
                    .navigationTitle(conversation.title)
            } else {
                ContentUnavailableView(
                    "Conversation not found",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("It may have been deleted.")
                )
                .navigationTitle("Chat")
            }
        }
        .instrumentNavigationBar()
        .instrumentHidesSystemBackButton()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                InstrumentBackButton()
            }
            .instrumentFlatToolbarItem()

            ToolbarItem(placement: .topBarTrailing) {
                chatOverflowMenu
            }
            .instrumentFlatToolbarItem()
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ChatViewModel(conversationID: conversationID, modelContext: modelContext)
            }
        }
        .onDisappear {
            viewModel?.stopGeneration()
        }
    }

    @ViewBuilder
    private func chatContent(conversation: Conversation) -> some View {
        if let viewModel {
            ChatThreadBody(
                conversation: conversation,
                viewModel: viewModel,
                isModelReady: modelStore.isModelReady,
                bottomScrollAnchorID: bottomScrollAnchorID
            )
        } else {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background(colorScheme))
        }
    }

    private var chatOverflowMenu: some View {
        Menu {
            // Rename and Export arrive in Slices 7–8.
        } label: {
            InstrumentTintedGlyph(base: "⋯")
        }
        .accessibilityLabel("Conversation actions")
    }
}

// MARK: - Thread body (dedicated View + @Bindable for reliable compose observation)

private struct ChatThreadBody: View {
    @Environment(\.colorScheme) private var colorScheme

    let conversation: Conversation
    @Bindable var viewModel: ChatViewModel
    let isModelReady: Bool
    let bottomScrollAnchorID: String

    var body: some View {
        messageThread
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background(colorScheme))
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ChatComposeBar(
                    text: $viewModel.composeText,
                    isGenerating: viewModel.isGenerating,
                    isModelReady: isModelReady,
                    canSend: viewModel.canSend,
                    onSend: { viewModel.send(isModelReady: isModelReady, in: conversation) },
                    onStop: { viewModel.stopGeneration() }
                )
                .id(viewModel.isGenerating)
            }
    }

    private var messageThread: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Spacing.messageGap) {
                    let messages = viewModel.sortedMessages(for: conversation)
                    ForEach(messages) { message in
                        ChatMessageRow(
                            message: message,
                            isStreaming: viewModel.streamingMessageID == message.id,
                            isGenerating: viewModel.isGenerating
                        )
                        .id(message.id)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(bottomScrollAnchorID)
                }
                .padding(.horizontal, Theme.Spacing.screenHorizontal)
                .padding(.top, 20)
                .padding(.bottom, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.streamingMessageID) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.isGenerating) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: conversation.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: streamingDraftSignature) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onAppear {
                scrollToBottom(proxy: proxy, animated: false)
            }
        }
    }

    private var streamingDraftSignature: String {
        guard let streamingID = viewModel.streamingMessageID else { return "" }
        let message = conversation.messages.first { $0.id == streamingID }
        return message?.content ?? ""
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(bottomScrollAnchorID, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(bottomScrollAnchorID, anchor: .bottom)
        }
    }
}

// MARK: - Message row

private struct ChatMessageRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let message: Message
    let isStreaming: Bool
    let isGenerating: Bool

    private var isUser: Bool {
        message.role == ChatPromptMessage.roleUser
    }

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
            messageBubble

            if isStreaming, isGenerating {
                Text("Generating…")
                    .font(.system(size: 11, weight: .medium))
                    .kerning(0.66)
                    .textCase(.uppercase)
                    .foregroundStyle(Color(hex: "#7A8A82"))
                    .padding(.leading, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    private var messageBubble: some View {
        let displayText = bubbleText
        return Text(displayText)
            .font(.system(size: Theme.ChatTypography.bodySize))
            .lineSpacing(Theme.ChatTypography.bubbleLineSpacing)
            .foregroundStyle(Theme.textPrimary(colorScheme))
            .multilineTextAlignment(isUser ? .trailing : .leading)
            .frame(maxWidth: isUser ? 320 : .infinity, alignment: isUser ? .trailing : .leading)
            .padding(.horizontal, Theme.Spacing.bubbleHorizontal)
            .padding(.vertical, Theme.Spacing.bubbleVertical)
            .background(bubbleBackground)
            .clipShape(bubbleShape)
            .overlay {
                bubbleShape.strokeBorder(bubbleBorder, lineWidth: 1)
            }
    }

    private var bubbleText: String {
        if message.content.isEmpty, isStreaming {
            return " "
        }
        return message.content
    }

    private var bubbleBackground: some ShapeStyle {
        isUser ? AnyShapeStyle(Theme.userBubble) : AnyShapeStyle(Theme.surface(colorScheme))
    }

    private var bubbleBorder: Color {
        isUser ? Theme.accent.opacity(0.24) : Theme.border(colorScheme)
    }

    private var bubbleShape: UnevenRoundedRectangle {
        if isUser {
            UnevenRoundedRectangle(
                topLeadingRadius: Theme.Radius.lg,
                bottomLeadingRadius: Theme.Radius.lg,
                bottomTrailingRadius: 6,
                topTrailingRadius: Theme.Radius.lg,
                style: .continuous
            )
        } else {
            UnevenRoundedRectangle(
                topLeadingRadius: Theme.Radius.lg,
                bottomLeadingRadius: 6,
                bottomTrailingRadius: Theme.Radius.lg,
                topTrailingRadius: Theme.Radius.lg,
                style: .continuous
            )
        }
    }
}

#Preview {
    NavigationStack {
        ChatThreadView(conversationID: UUID())
    }
    .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
    .environment(ModelStore())
    .themedScreen()
}
