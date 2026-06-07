import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Binding var navigationPath: NavigationPath

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(ModelStore.self) private var modelStore

    @Query(sort: \Conversation.updatedAt, order: .reverse)
    private var conversations: [Conversation]

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
                                navigationPath.append(conversation.id)
                            } label: {
                                conversationRow(conversation)
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(listRowInsets)
                            .listRowBackground(Theme.background(colorScheme))
                            .listRowSeparatorTint(Theme.border(colorScheme))
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func createConversation() {
        let conversation = Conversation()
        modelContext.insert(conversation)
        navigationPath.append(conversation.id)
    }

    private func deleteConversation(_ conversation: Conversation) {
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

    NavigationStack(path: $navigationPath) {
        ConversationListView(navigationPath: $navigationPath)
            .navigationDestination(for: UUID.self) { conversationID in
                ChatThreadView(conversationID: conversationID)
            }
    }
    .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
    .environment(ModelStore())
    .themedScreen()
}
