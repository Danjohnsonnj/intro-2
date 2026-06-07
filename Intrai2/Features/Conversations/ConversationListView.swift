import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Conversation.updatedAt, order: .reverse)
    private var conversations: [Conversation]

    var body: some View {
        Group {
            if conversations.isEmpty {
                emptyState
            } else {
                List(conversations) { conversation in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(conversation.title)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Theme.textPrimary(colorScheme))
                        Text(conversation.updatedAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(Theme.textTertiary(colorScheme))
                    }
                    .listRowBackground(Theme.surface(colorScheme))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Intrai")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Slice 2: create conversation and push chat
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New conversation")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("No conversations")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary(colorScheme))
            Text("Tap + to start")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary(colorScheme))
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
    .preferredColorScheme(.dark)
}
