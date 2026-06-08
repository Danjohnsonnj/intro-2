import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Binding var navigationPath: NavigationPath
    @Binding var activeConversationID: UUID?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(ModelStore.self) private var modelStore

    @Query(sort: \Conversation.updatedAt, order: .reverse)
    private var conversations: [Conversation]

    @State private var exportShareItem: ExportShareItem?
    @State private var conversationToRename: Conversation?

    private var listRowInsets: EdgeInsets {
        EdgeInsets(
            top: Theme.Spacing.listRowVertical,
            leading: Theme.Spacing.listRowHorizontal,
            bottom: Theme.Spacing.listRowVertical,
            trailing: Theme.Spacing.listRowHorizontal
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if modelStore.showsNoModelBanner {
                NavigationLink {
                    SettingsView()
                } label: {
                    NoModelBannerView()
                }
                .buttonStyle(.plain)
            }

            Group {
                if conversations.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(conversations) { conversation in
                            Button {
                                openConversation(conversation)
                            } label: {
                                conversationRow(conversation)
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(listRowInsets)
                            .listRowBackground(rowBackground(for: conversation))
                            .listRowSeparatorTint(Theme.border(colorScheme))
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    conversationToRename = conversation
                                } label: {
                                    Text("Rename")
                                }
                                .tint(Theme.surfaceRaised(colorScheme))

                                Button {
                                    exportShareItem = ConversationExport.shareItem(for: conversation)
                                } label: {
                                    Text("Export")
                                }
                                .tint(Theme.accent)
                                .disabled(conversation.messages.isEmpty)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteConversation(conversation)
                                } label: {
                                    Text("Delete")
                                }
                                .tint(Theme.swipeDelete)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .instrumentListNavigationTitle("Conversations")
        .instrumentNavigationBar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                InstrumentListNavActions(onNewConversation: createConversation)
            }
            .instrumentFlatToolbarItem()
        }
        .sheet(item: $exportShareItem) { item in
            ConversationShareSheet(items: [item.url])
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: renameSheetIsPresented) {
            if let conversationToRename {
                ConversationRenameSheet(conversation: conversationToRename)
            }
        }
        .onAppear {
            modelStore.refreshFromManager()
        }
        .onReceive(NotificationCenter.default.publisher(for: .intraiModelAvailabilityDidChange)) { _ in
            modelStore.refreshFromManager()
        }
    }

    private func conversationRow(_ conversation: Conversation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(conversation.title)
                .font(.listRowTitle)
                .foregroundStyle(Theme.textPrimary(colorScheme))
                .lineLimit(1)
            Text(ConversationTimestampFormatter.string(for: conversation.updatedAt))
                .listTimestampStyle(colorScheme)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func rowBackground(for conversation: Conversation) -> some View {
        let isActive = conversation.id == activeConversationID

        ZStack(alignment: .leading) {
            (isActive ? Theme.accentSubtle : Theme.background(colorScheme))

            if isActive {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Theme.accent)
                    .frame(width: 3)
                    .padding(.vertical, 10)
            }
        }
    }

    private var renameSheetIsPresented: Binding<Bool> {
        Binding(
            get: { conversationToRename != nil },
            set: { isPresented in
                if !isPresented {
                    conversationToRename = nil
                }
            }
        )
    }

    private func openConversation(_ conversation: Conversation) {
        activeConversationID = conversation.id
        navigationPath.append(conversation.id)
    }

    private func createConversation() {
        let conversation = Conversation()
        modelContext.insert(conversation)
        activeConversationID = conversation.id
        navigationPath.append(conversation.id)
    }

    private func deleteConversation(_ conversation: Conversation) {
        if activeConversationID == conversation.id {
            activeConversationID = nil
        }
        modelContext.delete(conversation)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Spacer()
            Text("No conversations")
                .font(.emptyStateTitle)
                .foregroundStyle(Theme.textSecondary(colorScheme))
            Text("Tap + to start")
                .font(.emptyStateHint)
                .foregroundStyle(Theme.textTertiary(colorScheme))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    @Previewable @State var navigationPath = NavigationPath()
    @Previewable @State var activeConversationID: UUID?

    NavigationStack(path: $navigationPath) {
        ConversationListView(
            navigationPath: $navigationPath,
            activeConversationID: $activeConversationID
        )
        .navigationDestination(for: UUID.self) { conversationID in
            ChatThreadView(conversationID: conversationID)
        }
    }
    .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
    .environment(ModelStore())
    .themedScreen()
}
