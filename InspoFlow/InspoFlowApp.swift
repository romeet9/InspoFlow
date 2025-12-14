import SwiftUI
import SwiftData

@main
struct InspoFlowApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SavedItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @StateObject private var screenshotService = ScreenshotService()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.light) // Enforce the Light Theme
                .environmentObject(screenshotService) // Inject Globally
                .onAppear {
                    // Inject Context and Start Service
                    screenshotService.setContext(sharedModelContainer.mainContext)
                    screenshotService.requestPermission()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
