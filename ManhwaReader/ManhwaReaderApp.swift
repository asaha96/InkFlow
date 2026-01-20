import SwiftUI
import SwiftData

@main
struct ManhwaReaderApp: App {
    @AppStorage("ghostModeEnabled") private var ghostModeEnabled = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Manga.self, Chapter.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(ImageLoader())
                .environment(HapticManager())
        }
        .modelContainer(ghostModeEnabled ? ModelContainer.inMemory : sharedModelContainer)
    }
}

extension ModelContainer {
    static var inMemory: ModelContainer {
        let schema = Schema([Manga.self, Chapter.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }
}
