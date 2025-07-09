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
    
    private let domain: String
    private let deviceIdentifier = DeviceIdentifier()
    
    private static let DEFAULT_DOMAIN = "bg-services-qa-api.adgeist.ai"
    
    private init(domain: String) {
        self.domain = domain
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
    
    public func getCreative() -> FetchCreative {
        return FetchCreative(deviceIdentifier: deviceIdentifier, domain: domain)
    }
    
    public func postCreativeAnalytics() -> CreativeAnalytics {
        return CreativeAnalytics(deviceIdentifier: deviceIdentifier, domain: domain)
    }
}