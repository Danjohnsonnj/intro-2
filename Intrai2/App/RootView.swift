import SwiftData
import SwiftUI

struct RootView: View {
    @State private var modelStore = ModelStore()
    @State private var inferenceSettingsStore = InferenceSettingsStore()
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ConversationListView(navigationPath: $navigationPath)
                .navigationDestination(for: UUID.self) { conversationID in
                    ChatThreadView(conversationID: conversationID)
                }
        }
        .themedScreen()
        .environment(modelStore)
        .environment(inferenceSettingsStore)
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
