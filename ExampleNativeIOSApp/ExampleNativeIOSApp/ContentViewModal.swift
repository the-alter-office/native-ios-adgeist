import Foundation
import AdgeistKit

final class ContentViewModel: ObservableObject {    
    // Cache the core instance and its components
    private let adgeistCore: AdgeistCore
    private let creative: FetchCreative
    private let creativeAnalytics: CreativeAnalytics
    
    init() {
        // Initialize once and cache
        self.adgeistCore = AdgeistCore.initialize(customBidRequestBackendDomain: "https://beta.v2.bg-services.adgeist.ai")
        self.creative = adgeistCore.getCreative()
        self.creativeAnalytics = adgeistCore.postCreativeAnalytics()
    }

    func generateActivity() {
    }
    
    func setUserDetails() {
        let userDetails = UserDetails(
            userId: "1",
            userName: "kishore",
            email: "john@example.com",
            phone: "+911234567890"
        )
        adgeistCore.setUserDetails(userDetails)
        print("User details set successfully")
    }

    func logEvent() {
        let eventProps: [String: Any] = [
            "screen": "home",
            "search_query": "Moto Edge Pro",
            "timestamp": Date().timeIntervalSince1970
        ]
        let event = Event(
            eventType: "search",
            eventProperties: eventProps
        )
        adgeistCore.logEvent(event)
        print("Search event logged with properties: \(eventProps)")
    }
    
    func logCustomEvent(eventType: String, properties: [String: Any] = [:]) {
        let event = Event(
            eventType: eventType,
            eventProperties: properties
        )
        adgeistCore.logEvent(event)
        print("Custom event '\(eventType)' logged with properties: \(properties)")
    }

    func getConsentStatus() -> Bool {
        let consentStatus = adgeistCore.getConsentStatus()
        print("Current consent status: \(consentStatus)")
        return consentStatus
    }

    func updateConsentStatus(_ granted: Bool) {
        adgeistCore.updateConsentStatus(granted)
        print("Consent status updated to: \(granted)")
        
        // Log consent change event
        logCustomEvent(
            eventType: "consent_changed",
            properties: ["granted": granted, "timestamp": Date().timeIntervalSince1970]
        )
    }
}
