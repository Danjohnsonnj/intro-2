import SwiftData
import SwiftUI

@main
struct Intrai2App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Conversation.self,
            Message.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
