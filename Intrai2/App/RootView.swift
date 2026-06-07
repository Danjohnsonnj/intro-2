import SwiftData
import SwiftUI

struct RootView: View {
    @State private var modelStore = ModelStore()

    var body: some View {
        NavigationStack {
            ConversationListView()
        }
        .themedScreen()
        .environment(modelStore)
        .task {
            modelStore.bootstrap()
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
        .preferredColorScheme(.dark)
}
