import Foundation
import AdgeistKit

final class ContentViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var activityDescription = "Tap 👇 to generate an activity"
    @Published var creativeData: Any?
    @Published var errorMessage: String?
    
    // Cache the core instance and its components
    private let adgeistCore: AdgeistCore
    private let creative: FetchCreative
    private let creativeAnalytics: CreativeAnalytics
    
    // Configuration constants
    private struct Config {
        static let apiKey = "b4e33bb73061d4e33670f229033f14bf770d35b15512dc1f106529e38946e49c"
        static let origin = "https://adgeist-ad-integration.d49kd6luw1c4m.amplifyapp.com"
        static let adSpaceId = "691af20e4d10c63aa7ba7140"
        static let companyId = "68f91f09c40a64049896acab"
        static let isTestEnvironment = true
    }

    init() {
        // Initialize once and cache
        self.adgeistCore = AdgeistCore.initialize(customBidRequestBackendDomain: "beta.v2.bg-services.adgeist.ai")
        self.creative = adgeistCore.getCreative()
        self.creativeAnalytics = adgeistCore.postCreativeAnalytics()
    }

    func generateActivity() {
        isLoading = true
        errorMessage = nil
        activityDescription = "Loading creative..."
        
        creative.fetchCreative(
            adUnitID: Config.adSpaceId,
            buyType: "FIXED",
            isTestEnvironment: Config.isTestEnvironment
        ) { [weak self] creativeData in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let creativeData = creativeData {
                    self?.creativeData = creativeData
                    self?.activityDescription = "Creative loaded successfully! 🎉"
                    print("Creative fetched successfully: \(creativeData)")
                    
                    // Track impression after successful load
                    self?.trackImpression(for: creativeData)
                } else {
                    self?.errorMessage = "Failed to load creative"
                    self?.activityDescription = "Failed to load creative ❌"
                    print("Failed to fetch creative")
                }
            }
        }
    }
    
    private func trackImpression(for creativeData: Any) {
        if let fixedAd = creativeData as? FixedAdResponse {
            guard let campaignId = fixedAd.campaignId else {
                print("No campaign ID for impression tracking")
                return
            }
            // Use AnalyticsRequestDEPRECATED for FIXED
            let analyticsRequest = AnalyticsRequestDEPRECATED.AnalyticsRequestBuilderDEPRECATED(adUnitID: Config.adSpaceId, isTestMode: Config.isTestEnvironment)
                .buildFIXEDRequest(metaData: fixedAd.metaData)
                .trackImpression(renderTime: 1.5)
                .build()
            creativeAnalytics.sendTrackingData(analyticsRequestDEPRECATED: analyticsRequest)
            print("Impression tracked for fixed ad: \(campaignId)")
        } else if let cpmAd = creativeData as? CPMAdResponse {
            guard let data = cpmAd.data,
                  let firstSeatBid = data.seatBid.first,
                  let firstBid = firstSeatBid.bid.first else {
                print("No valid bid data for impression tracking")
                return
            }
            // Use AnalyticsRequestDEPRECATED for CPM
            let analyticsRequest = AnalyticsRequestDEPRECATED.AnalyticsRequestBuilderDEPRECATED(adUnitID: Config.adSpaceId, isTestMode: Config.isTestEnvironment)
                .buildCPMRequest(campaignID: firstBid.id, bidID: data.bidId)
                .trackImpression(renderTime: 1.5)
                .build()
            creativeAnalytics.sendTrackingData(analyticsRequestDEPRECATED: analyticsRequest)
            print("Impression tracked for CPM ad: \(firstBid.id)")
        }
    }
    
    func trackClick() {
        guard let creativeData = creativeData else {
            print("No creative data available for click tracking")
            return
        }
        if let fixedAd = creativeData as? FixedAdResponse {
            guard let campaignId = fixedAd.campaignId else {
                print("No campaign ID for click tracking")
                return
            }
            let analyticsRequest = AnalyticsRequestDEPRECATED.AnalyticsRequestBuilderDEPRECATED(adUnitID: Config.adSpaceId, isTestMode: Config.isTestEnvironment)
                .buildFIXEDRequest(metaData: fixedAd.metaData)
                .trackClick()
                .build()
            creativeAnalytics.sendTrackingData(analyticsRequestDEPRECATED: analyticsRequest)
            print("Click tracked for fixed ad: \(campaignId)")
        } else if let cpmAd = creativeData as? CPMAdResponse {
            guard let data = cpmAd.data,
                  let firstSeatBid = data.seatBid.first,
                  let firstBid = firstSeatBid.bid.first else {
                print("No creative data available for click tracking")
                return
            }
            let analyticsRequest = AnalyticsRequestDEPRECATED.AnalyticsRequestBuilderDEPRECATED(adUnitID: Config.adSpaceId, isTestMode: Config.isTestEnvironment)
                .buildCPMRequest(campaignID: firstBid.id, bidID: data.bidId)
                .trackClick()
                .build()
            creativeAnalytics.sendTrackingData(analyticsRequestDEPRECATED: analyticsRequest)
            print("Click tracked for CPM ad: \(firstBid.id)")
        }
    }
    
    func trackView(viewTime: Float, visibilityRatio: Float = 1.0, scrollDepth: Float = 0.5) {
        guard let creativeData = creativeData else {
            print("No creative data available for view tracking")
            return
        }
        if let fixedAd = creativeData as? FixedAdResponse {
            guard let campaignId = fixedAd.campaignId else {
                print("No campaign ID for view tracking")
                return
            }
            let analyticsRequest = AnalyticsRequestDEPRECATED.AnalyticsRequestBuilderDEPRECATED(adUnitID: Config.adSpaceId, isTestMode: Config.isTestEnvironment)
                .buildFIXEDRequest(metaData: fixedAd.metaData)
                .trackViewableImpression(timeToVisible: 0.5, scrollDepth: scrollDepth, visibilityRatio: visibilityRatio, viewTime: viewTime)
                .build()
            creativeAnalytics.sendTrackingData(analyticsRequestDEPRECATED: analyticsRequest)
            print("View tracked for fixed ad: viewTime=\(viewTime), visibilityRatio=\(visibilityRatio)")
        } else if let cpmAd = creativeData as? CPMAdResponse {
            guard let data = cpmAd.data,
                  let firstSeatBid = data.seatBid.first,
                  let firstBid = firstSeatBid.bid.first else {
                print("No creative data available for view tracking")
                return
            }
            let analyticsRequest = AnalyticsRequestDEPRECATED.AnalyticsRequestBuilderDEPRECATED(adUnitID: Config.adSpaceId, isTestMode: Config.isTestEnvironment)
                .buildCPMRequest(campaignID: firstBid.id, bidID: data.bidId)
                .trackViewableImpression(timeToVisible: 0.5, scrollDepth: scrollDepth, visibilityRatio: visibilityRatio, viewTime: viewTime)
                .build()
            creativeAnalytics.sendTrackingData(analyticsRequestDEPRECATED: analyticsRequest)
            print("View tracked for CPM ad: viewTime=\(viewTime), visibilityRatio=\(visibilityRatio)")
        }
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
