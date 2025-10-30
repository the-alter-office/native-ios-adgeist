//
//  AdgeistCore.swift
//  AdgeistKit
//
//  Created by kishore on 02/05/25.
//

import Foundation

public final class AdgeistCore {
    public static var shared: AdgeistCore {
        guard let instance = _instance else {
            fatalError("AdgeistCore is not initialized. Call initialize(customDomain:) first.")
        }
        return instance
    }
    
    private static var _instance: AdgeistCore?
    private static let lock = NSLock()
    
    private let defaults = UserDefaults.standard
    private let PREFS_NAME = "AdgeistPrefs" 
    private let KEY_CONSENT = "adgeist_consent"
    private var consentGiven: Bool = false

    private let domain: String
    private let deviceIdentifier: DeviceIdentifier
    private var userDetails: UserDetails?
    private let cdpClient: CdpClient
    private let targetingInfo: [String: Any]

    private static let DEFAULT_DOMAIN = "bg-services-qa-api.adgeist.ai"
    private static let bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJraXNob3JlIiwiaWF0IjoxNzU0Mzc1NzIwLCJuYmYiOjE3NTQzNzU3MjAsImV4cCI6MTc1Nzk3NTcyMCwianRpIjoiOTdmNTI1YjAtM2NhNy00MzQwLTlhOGItZDgwZWI2ZjJmOTAzIiwicm9sZSI6ImFkbWluIiwic2NvcGUiOiJpbmdlc3QiLCJwbGF0Zm9ybSI6Im1vYmlsZSIsImNvbXBhbnlfaWQiOiJraXNob3JlIiwiaXNzIjoiQWRHZWlzdC1DRFAifQ.IYQus53aQETqOaQzEED8L51jwKRN3n-Oq-M8jY_ZSaw"

    private init(domain: String) {
        self.consentGiven = defaults.bool(forKey: KEY_CONSENT)
        self.domain = domain
        self.deviceIdentifier = DeviceIdentifier()
        self.cdpClient = CdpClient(deviceIdentifier: self.deviceIdentifier, bearerToken: AdgeistCore.bearerToken)
        self.targetingInfo = TargetingOptions().getTargetingInfo()
    }
    
    public static func initialize(customDomain: String? = nil) -> AdgeistCore {
        lock.lock()
        defer { lock.unlock() }
        
        if _instance == nil {
            _instance = AdgeistCore(domain: customDomain ?? DEFAULT_DOMAIN)
        }
        return _instance!
    }
    
    public static func getInstance() -> AdgeistCore {
        guard let instance = _instance else {
            fatalError("AdgeistCore is not initialized. Call initialize(customDomain:) first.")
        }
        return instance
    }
    
    public func setUserDetails(_ details: UserDetails) {
        objc_sync_enter(self)
        self.userDetails = details
        objc_sync_exit(self)
    }

    public func updateConsentStatus(_ consentGiven: Bool) {
        self.consentGiven = consentGiven
        defaults.set(consentGiven, forKey: KEY_CONSENT)
    }

    public func getConsentStatus() -> Bool {
        return consentGiven
    }

    public func getCreative() -> FetchCreative {
        return FetchCreative(deviceIdentifier: deviceIdentifier, domain: domain, targetingInfo: targetingInfo)
    }
    
    public func postCreativeAnalytics() -> CreativeAnalytics {
        return CreativeAnalytics(deviceIdentifier: deviceIdentifier, domain: domain)
    }

    public func logEvent(_ event: Event) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            var parameters: [String: Any] = event.eventProperties ?? [:]
            if let userDetails = self.userDetails {
                parameters["userDetails"] = userDetails.toDictionary()
            }
            let fullEvent = Event(eventType: event.eventType, eventProperties: parameters)
            self.cdpClient.sendEventToCdp(fullEvent, consentGiven: self.consentGiven)
        }
    }
}
