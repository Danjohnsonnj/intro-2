import SwiftData
import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            ConversationListView()
        }
        .themedScreen()
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
        .preferredColorScheme(.dark)
}
