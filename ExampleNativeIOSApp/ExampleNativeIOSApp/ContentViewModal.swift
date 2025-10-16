//
//  ContentViewModal.swift
//  ExampleNativeIOSApp
//
//  Created by kishore on 02/05/25.
//

import Foundation
import AdgeistKit

final class ContentViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var activityDescription = "Tap 👇 to generate an activity"
    @Published var creativeData: CreativeDataModel?
    @Published var errorMessage: String?
    
    // Cache the core instance and its components
    private let adgeistCore: AdgeistCore
    private let creative: FetchCreative
    private let creativeAnalytics: CreativeAnalytics
    
    // Configuration constants
    private struct Config {
        static let apiKey = "48ad37bbe0c4091dee7c4500bc510e4fca6e7f7a1c293180708afa292820761c"
        static let origin = "https://adgeist-ad-integration.d49kd6luw1c4m.amplifyapp.com"
        static let adSpaceId = "68ef39e281029bf4edcd62ea"
        static let companyId = "68e4baa14040394a656d5262"
        static let isTestEnvironment = true
    }

    init() {
        // Initialize once and cache
        self.adgeistCore = AdgeistCore.initialize(customDomain: "bg-services-qa-api.adgeist.ai")
        self.creative = adgeistCore.getCreative()
        self.creativeAnalytics = adgeistCore.postCreativeAnalytics()
    }

    func generateActivity() {
        isLoading = true
        errorMessage = nil
        activityDescription = "Loading creative..."
        
        creative.fetchCreative(
            apiKey: Config.apiKey,
            origin: Config.origin,
            adSpaceId: Config.adSpaceId,
            companyId: Config.companyId,
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
    
    private func trackImpression(for creativeData: CreativeDataModel) {
        guard let data = creativeData.data,
              let firstSeatBid = data.seatBid.first,
              let firstBid = firstSeatBid.bid.first else {
            print("No valid bid data for impression tracking")
            return
        }
        
        creativeAnalytics.trackImpression(
            campaignId: firstBid.id,
            adSpaceId: Config.adSpaceId,
            publisherId: Config.companyId,
            apiKey: Config.apiKey,
            bidId: data.bidId,
            isTestEnvironment: Config.isTestEnvironment,
            renderTime: 1.5 // You can measure actual render time
        )
    }
    
    func trackClick() {
        guard let creativeData = creativeData,
              let data = creativeData.data,
              let firstSeatBid = data.seatBid.first,
              let firstBid = firstSeatBid.bid.first else {
            print("No creative data available for click tracking")
            return
        }
        
        creativeAnalytics.trackClick(
            campaignId: firstBid.id,
            adSpaceId: Config.adSpaceId,
            publisherId: Config.companyId,
            apiKey: Config.apiKey,
            bidId: data.bidId,
            isTestEnvironment: Config.isTestEnvironment
        )
        
        print("Click tracked for campaign: \(firstBid.id)")
    }
    
    func trackView(viewTime: Float, visibilityRatio: Float = 1.0, scrollDepth: Float = 0.5) {
        guard let creativeData = creativeData,
              let data = creativeData.data,
              let firstSeatBid = data.seatBid.first,
              let firstBid = firstSeatBid.bid.first else {
            print("No creative data available for view tracking")
            return
        }
        
        creativeAnalytics.trackView(
            campaignId: firstBid.id,
            adSpaceId: Config.adSpaceId,
            publisherId: Config.companyId,
            apiKey: Config.apiKey,
            bidId: data.bidId,
            isTestEnvironment: Config.isTestEnvironment,
            viewTime: viewTime,
            visibilityRatio: visibilityRatio,
            scrollDepth: scrollDepth,
            timeToVisible: 0.5
        )
        
        print("View tracked: viewTime=\(viewTime), visibilityRatio=\(visibilityRatio)")
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