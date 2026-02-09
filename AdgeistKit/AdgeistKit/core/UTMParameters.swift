import Foundation

/// Represents UTM parameters used for tracking marketing campaigns
public struct UTMParameters: Codable, Equatable {
    public let source: String?      // utm_source: identifies which site sent the traffic
    public let campaign: String?    // utm_campaign: identifies a specific campaign
    public let data: String?        // utm_data: identifies meta data
    public let sessionId: String?   // Unique session identifier
    
    public init(source: String? = nil,
                campaign: String? = nil,
                data: String? = nil,
                sessionId: String? = nil) {
        self.source = source
        self.campaign = campaign
        self.data = data
        self.sessionId = sessionId
    }
    
    /// Parse UTM parameters from URL
    public init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            return nil
        }
        
        var utmSource: String?
        var utmCampaign: String?
        var utmData: String?
        
        for item in queryItems {
            switch item.name.lowercased() {
            case "utm_source":
                utmSource = item.value
            case "utm_campaign":
                utmCampaign = item.value
            case "utm_data":
                utmData = item.value
            default:
                break
            }
        }
        
        // Only create if at least one UTM parameter exists
        guard utmSource != nil || utmCampaign != nil || utmData != nil else {
            return nil
        }
        
        self.source = utmSource
        self.campaign = utmCampaign
        self.data = utmData
        self.sessionId = nil
    }
    
    /// Create from dictionary
    public static func fromMap(_ map: [String: String?]) -> UTMParameters {
        return UTMParameters(
            source: map["utm_source"] ?? nil,
            campaign: map["utm_campaign"] ?? nil,
            data: map["utm_data"] ?? nil,
            sessionId: map["session_id"] ?? nil
        )
    }
    
    /// Convert to dictionary for analytics/tracking
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        if let source = source { dict["utm_source"] = source }
        if let campaign = campaign { dict["utm_campaign"] = campaign }
        if let data = data { dict["utm_data"] = data }
        if let sessionId = sessionId { dict["session_id"] = sessionId }
        
        return dict
    }
    
    /// Check if this has any UTM data
    public func hasData() -> Bool {
        return source != nil || campaign != nil || data != nil
    }
}
