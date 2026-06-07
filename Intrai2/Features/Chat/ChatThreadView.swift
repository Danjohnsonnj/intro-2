import SwiftData
import SwiftUI

/// Empty chat shell — Slice 3 adds thread, compose, and streaming.
struct ChatThreadView: View {
    let conversationID: UUID

    @Environment(\.colorScheme) private var colorScheme
    @Query private var matches: [Conversation]

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
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.background(colorScheme))
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
        }
    }
}

#Preview {
    NavigationStack {
        ChatThreadView(conversationID: UUID())
    }
    .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
    .themedScreen()
}
