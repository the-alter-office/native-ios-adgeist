//
//  AdgeistConfig.swift
//  AdgeistKit
//
//  Created by kishore on 27/11/25.
//

import Foundation

public class AdgeistConfig {
    private static let API_KEY = "AdgeistAPIKey"
    private static let APP_ID = "AdgeistAppID"
    private static let ORIGIN = "AdgeistOrigin"
    
    public static func getAPIKey() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: API_KEY) as? String
    }
    
    public static func getAppID() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: APP_ID) as? String
    }
    
    public static func getOrigin() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: ORIGIN) as? String
    }
    
    public static func isConfigured() -> Bool {
        guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
            print("⚠️ AdgeistKit: API Key not configured in Info.plist. Add 'AdgeistAPIKey' key.")
            return false
        }
        
        guard let appId = getAppID(), !appId.isEmpty else {
            print("⚠️ AdgeistKit: App ID not configured in Info.plist. Add 'AdgeistAppID' key.")
            return false
        }
        
        guard let origin = getOrigin(), !origin.isEmpty else {
            print("⚠️ AdgeistKit: Origin not configured in Info.plist. Add 'AdgeistOrigin' key.")
            return false
        }
        
        print("✅ AdgeistKit: Configuration validated successfully")
        print("   App ID: \(appId)")
        print("   API Key: \(apiKey.prefix(10))...")
        print("   Origin: \(origin)")
        
        return true
    }
    
    public static func getAllConfig() -> [String: String] {
        var config: [String: String] = [:]
        
        if let apiKey = getAPIKey() {
            config["apiKey"] = apiKey
        }
        
        if let appId = getAppID() {
            config["appId"] = appId
        }
        
        if let origin = getOrigin() {
            config["origin"] = origin
        }
        
        return config
    }
}
