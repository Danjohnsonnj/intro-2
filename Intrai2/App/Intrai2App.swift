import SwiftData
import SwiftUI

@main
struct Intrai2App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Conversation.self,
            Message.self,
        ])

        let storeURL = Self.swiftDataStoreURL()
        Self.ensureApplicationSupportDirectoryExists(for: storeURL)

        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private static func swiftDataStoreURL() -> URL {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Application Support directory is unavailable.")
        }
        return appSupport.appendingPathComponent("default.store", isDirectory: false)
    }

    private static func ensureApplicationSupportDirectoryExists(for storeURL: URL) {
        let directory = storeURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            fatalError("Could not create Application Support directory: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
