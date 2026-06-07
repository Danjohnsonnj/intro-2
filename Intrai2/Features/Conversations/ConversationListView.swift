import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.colorScheme) private var colorScheme
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
                    List(conversations) { conversation in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(conversation.title)
                                .font(.listRowTitle)
                                .foregroundStyle(Theme.textPrimary(colorScheme))
                                .lineLimit(1)
                            Text(ConversationTimestampFormatter.string(for: conversation.updatedAt))
                                .listTimestampStyle(colorScheme)
                        }
                        .listRowInsets(listRowInsets)
                        .listRowBackground(Theme.background(colorScheme))
                        .listRowSeparatorTint(Theme.border(colorScheme))
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
                InstrumentListNavActions {
                    // Slice 2: create conversation and push chat
                }
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
    NavigationStack {
        ConversationListView()
    }
    .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
    .environment(ModelStore())
    .themedScreen()
}
