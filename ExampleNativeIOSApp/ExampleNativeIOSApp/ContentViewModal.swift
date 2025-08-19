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
    
    private var adgeistCore: AdgeistCore!

    init() {
        adgeistCore = AdgeistCore.initialize(customDomain: "bg-services-api.adgeist.ai")
    }


    func generateActivity() {
        let adgeistCoreInstance = AdgeistCore.getInstance()
        
        let creative = adgeistCoreInstance.getCreative()
        let creativeAnalytics = adgeistCoreInstance.postCreativeAnalytics()

        creative.fetchCreative(
            apiKey: "7f6b3361bd6d804edfb40cecf3f42e5ebc0b11bd88d96c8a6d64188b93447ad9",
            origin: "https://adgeist-ad-integration.d49kd6luw1c4m.amplifyapp.com",
            adSpaceId: "686149fac1fd09fff371e53c",
            companyId: "67f8ad1350ff1e0870da3f5b",
            isTestEnvironment: true
        ) { creativeData in
            print("success----------: \(creativeData)")
        }


        creativeAnalytics.sendTrackingData(
            campaignId: "68625075c1fd09fff371f925",
            adSpaceId: "686149fac1fd09fff371e53c",
            publisherId: "67f8ad1350ff1e0870da3f5b",
            eventType: "IMPRESSION",
            origin: "https://adgeist-ad-integration.d49kd6luw1c4m.amplifyapp.com",
            apiKey: "7f6b3361bd6d804edfb40cecf3f42e5ebc0b11bd88d96c8a6d64188b93447ad9",
            bidId: "fa08ae11-b649-4dd1-b68c-c1d217145ca4",
            isTestEnvironment: true
        ) { creativeData in
            print("success----------: \(creativeData)")
        }
    }

    func setUserDetails() {
        let adgeistCoreInstance = AdgeistCore.getInstance()
        let userDetails = UserDetails(
            userId: "1",
            userName: "kishore",
            email: "john@example.com",
            phone: "+911234567890"
        )
        adgeistCoreInstance.setUserDetails(userDetails)
        print("User details set")
    }


    func logEvent() {
        let adgeistCoreInstance = AdgeistCore.getInstance()
        let eventProps: [String: Any] = [
            "screen": "home",
            "search_query": "Moto Edge Pro"
        ]
        let event = Event(
            eventType: "search",
            eventProperties: eventProps
        )
        adgeistCoreInstance.logEvent(event)
        print("Event logged")
    }

    func getConsentStatus(){
        let adgeistCoreInstance = AdgeistCore.getInstance()
        let consentStatus = adgeistCoreInstance.getConsentStatus()
        print("Consent status: \(consentStatus)")
    }

    func updateConsentStatus(){
        let adgeistCoreInstance = AdgeistCore.getInstance()
        adgeistCoreInstance.updateConsentStatus(true)
        print("Consent status updated")
    }
}
