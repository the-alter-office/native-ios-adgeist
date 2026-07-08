import SwiftUI
import SwiftData
import AdgeistKit

@main
struct ExampleNativeIOSAppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .onOpenURL { url in
                    handleDeeplink(url: url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    /// Handle deeplinks
    private func handleDeeplink(url: URL) {
        print("Deeplink received: \(url)")

        // Get AdgeistCore instance if initialized
        if let adgeistCore = try? AdgeistCore.getInstance() {
            let event = Event(
                eventType: "deeplink_opened",
                eventProperties: ["url": url.absoluteString]
            )
            adgeistCore.logEvent(event)
        } else {
            print("AdgeistCore not initialized yet")
        }
    }
}
