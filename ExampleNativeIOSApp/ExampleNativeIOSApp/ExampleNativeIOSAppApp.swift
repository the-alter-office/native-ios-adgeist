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
            ContentView()
                .onOpenURL { url in
                    handleDeeplink(url: url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    /// Handle deeplinks and track UTM parameters
    private func handleDeeplink(url: URL) {
        print("Deeplink received: \(url)")
        
        // Get AdgeistCore instance if initialized
        if let adgeistCore = try? AdgeistCore.getInstance() {
            // Track the deeplink with UTM parameters
            adgeistCore.trackDeeplink(url: url)
            
            // Optionally log an event
            let event = Event(
                eventType: "deeplink_opened",
                eventProperties: ["url": url.absoluteString]
            )
            adgeistCore.logEvent(event)
            
            print("UTM Data: \(adgeistCore.getUTMData())")
        } else {
            print("AdgeistCore not initialized yet, UTM tracking will occur on next launch")
        }
    }
}
