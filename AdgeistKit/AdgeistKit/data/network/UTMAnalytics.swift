import Foundation

/// Handles sending analytics events for UTM tracking
public class UTMAnalytics {
    private let adgeistCore: AdgeistCore
    private static let TAG = "UTMAnalytics"
    
    init(adgeistCore: AdgeistCore) {
        self.adgeistCore = adgeistCore
    }
    
    /// Send a VISIT event with UTM parameters
    /// Called automatically when UTM parameters are captured
    public func sendVisitEvent(utmParameters: UTMParameters) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            // Prepare event properties with UTM data
            var eventProperties = utmParameters.toDictionary()
            eventProperties["event_category"] = "utm_tracking"
            eventProperties["platform"] = "ios"
            eventProperties["sdk_version"] = self.getSDKVersion()
            
            // Create VISIT event
            let event = Event(eventType: "VISIT", eventProperties: eventProperties)
            
            // Log the event through AdgeistCore's CDP client
            self.adgeistCore.logEvent(event)
            
            print("\(Self.TAG): VISIT event sent with UTM data - source: \(utmParameters.source ?? "none"), campaign: \(utmParameters.campaign ?? "none")")
        }
    }
    
    /// Send an install attribution event (first launch only)
    public func sendInstallAttributionEvent(utmParameters: UTMParameters?) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            var eventProperties: [String: Any] = [
                "event_category": "install_attribution",
                "platform": "ios",
                "sdk_version": self.getSDKVersion(),
                "attributed": utmParameters != nil
            ]
            
            // Add UTM data if available
            if let utmParameters = utmParameters {
                eventProperties.merge(utmParameters.toDictionary()) { (_, new) in new }
            }
            
            // Create INSTALL event
            let event = Event(eventType: "INSTALL", eventProperties: eventProperties)
            
            // Log the event
            self.adgeistCore.logEvent(event)
            
            let attribution = utmParameters != nil ? "attributed" : "organic"
            print("\(Self.TAG): INSTALL event sent - \(attribution)")
        }
    }
    
    /// Send a deeplink opened event
    public func sendDeeplinkEvent(utmParameters: UTMParameters, url: URL) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            var eventProperties = utmParameters.toDictionary()
            eventProperties["event_category"] = "deeplink"
            eventProperties["platform"] = "ios"
            eventProperties["sdk_version"] = self.getSDKVersion()
            eventProperties["deeplink_url"] = url.absoluteString
            eventProperties["deeplink_scheme"] = url.scheme
            eventProperties["deeplink_host"] = url.host
            
            // Create DEEPLINK_OPENED event
            let event = Event(eventType: "DEEPLINK_OPENED", eventProperties: eventProperties)
            
            // Log the event
            self.adgeistCore.logEvent(event)
            
            print("\(Self.TAG): DEEPLINK_OPENED event sent - source: \(utmParameters.source ?? "none")")
        }
    }
    
    /// Send UTM update event when parameters change
    public func sendUTMUpdateEvent(previousUTM: UTMParameters?, newUTM: UTMParameters) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            var eventProperties = newUTM.toDictionary()
            eventProperties["event_category"] = "utm_update"
            eventProperties["platform"] = "ios"
            eventProperties["sdk_version"] = self.getSDKVersion()
            eventProperties["has_previous_utm"] = previousUTM != nil
            
            if let previousUTM = previousUTM {
                eventProperties["previous_source"] = previousUTM.source
                eventProperties["previous_campaign"] = previousUTM.campaign
                eventProperties["previous_medium"] = previousUTM.medium
            }
            
            // Create UTM_UPDATED event
            let event = Event(eventType: "UTM_UPDATED", eventProperties: eventProperties)
            
            // Log the event
            self.adgeistCore.logEvent(event)
            
            print("\(Self.TAG): UTM_UPDATED event sent")
        }
    }
    
    // MARK: - Private Helpers
    
    private func getSDKVersion() -> String {
        let frameworkBundle = Bundle(for: AdgeistCore.self)
        return frameworkBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }
}
