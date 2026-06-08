import SwiftData
import SwiftUI

struct ChatThreadView: View {
    let conversationID: UUID

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(ModelStore.self) private var modelStore
    @Query private var matches: [Conversation]

    @State private var viewModel: ChatViewModel?
    @State private var exportShareItem: ExportShareItem?

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
                chatOverflowMenu(conversation: conversation)
            }
            .instrumentFlatToolbarItem()
        }
        .sheet(item: $exportShareItem) { item in
            ConversationShareSheet(items: [item.url])
                .presentationDetents([.medium, .large])
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

    @ViewBuilder
    private func chatOverflowMenu(conversation: Conversation?) -> some View {
        Menu {
            if let conversation {
                Button {
                    exportConversation(conversation)
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(conversation.messages.isEmpty)
            }
            // Rename arrives in Slice 8.
        } label: {
            InstrumentTintedGlyph(base: "⋯")
        }
        .accessibilityLabel("Conversation actions")
    }

    private func exportConversation(_ conversation: Conversation) {
        do {
            let url = try ExportFormatter.writeTemporaryMarkdownFile(for: conversation)
            exportShareItem = ExportShareItem(url: url)
        } catch {
            // Export is best-effort; share sheet simply won't open on failure.
        }
    }
}

private struct ExportShareItem: Identifiable {
    let id = UUID()
    let url: URL
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
                    if viewModel.showTrimNotice {
                        ChatTrimNotice()
                    }

                    if let generationError = viewModel.generationError {
                        ChatGenerationErrorNotice(message: generationError)
                    }

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
            .onChange(of: viewModel.showTrimNotice) { _, _ in
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

// MARK: - Ephemeral notices

private struct ChatGenerationErrorNotice: View {
    @Environment(\.colorScheme) private var colorScheme

    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 13))
            .foregroundStyle(Theme.destructive)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.destructive.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(Theme.destructive.opacity(0.24), lineWidth: 1)
            }
    }
}

private struct ChatTrimNotice: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text("Earlier messages trimmed")
            .font(.system(size: 11, weight: .medium))
            .kerning(0.44)
            .textCase(.uppercase)
            .foregroundStyle(Theme.textTertiary(colorScheme))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay {
                Capsule()
                    .strokeBorder(Theme.border(colorScheme), lineWidth: 1)
            }
            .frame(maxWidth: .infinity)
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
        ChatMessageMarkdown(
            content: message.content,
            isStreaming: isStreaming,
            textAlignment: isUser ? .trailing : .leading
        )
        .frame(maxWidth: isUser ? 320 : .infinity, alignment: isUser ? .trailing : .leading)
        .padding(.horizontal, Theme.Spacing.bubbleHorizontal)
        .padding(.vertical, Theme.Spacing.bubbleVertical)
        .background(bubbleBackground)
        .clipShape(bubbleShape)
        .overlay {
            bubbleShape.strokeBorder(bubbleBorder, lineWidth: 1)
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = message.content
            } label: {
                Label("Copy markdown", systemImage: "doc.on.doc")
            }
            .disabled(message.content.isEmpty)
        }
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
