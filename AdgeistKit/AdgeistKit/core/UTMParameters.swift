import Foundation

/// Represents UTM parameters used for tracking marketing campaigns
public struct UTMParameters: Codable, Equatable {
    public let source: String?      // utm_source: identifies which site sent the traffic
    public let medium: String?      // utm_medium: identifies what type of link was used
    public let campaign: String?    // utm_campaign: identifies a specific campaign
    public let term: String?        // utm_term: identifies search terms
    public let content: String?     // utm_content: identifies what specifically was clicked
    public let x_data: String?        // utm_term: identifies meta data
    public let capturedAt: Date     // When these UTM params were captured
    public let captureType: CaptureType  // How they were captured
    
    public enum CaptureType: String, Codable {
        case install = "install"           // First app install/launch
        case deeplink = "deeplink"         // From a deeplink
        case universal = "universal_link"  // From a universal link
    }
    
    public init(source: String? = nil,
                medium: String? = nil,
                campaign: String? = nil,
                term: String? = nil,
                content: String? = nil,
                x_data: String? = nil,
                capturedAt: Date = Date(),
                captureType: CaptureType = .deeplink) {
        self.source = source
        self.medium = medium
        self.campaign = campaign
        self.term = term
        self.content = content
        self.x_data = x_data
        self.capturedAt = capturedAt
        self.captureType = captureType
    }
    
    /// Parse UTM parameters from URL
    public init?(url: URL, captureType: CaptureType = .deeplink) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            return nil
        }
        
        var utmSource: String?
        var utmMedium: String?
        var utmCampaign: String?
        var utmTerm: String?
        var utmContent: String?
        var utmXData: String?
        
        for item in queryItems {
            switch item.name.lowercased() {
            case "utm_source":
                utmSource = item.value
            case "utm_medium":
                utmMedium = item.value
            case "utm_campaign":
                utmCampaign = item.value
            case "utm_term":
                utmTerm = item.value
            case "utm_content":
                utmContent = item.value
            case "utm_x_data":
                utmXData = item.value    
            default:
                break
            }
        }
        
        // Only create if at least one UTM parameter exists
        guard utmSource != nil || utmMedium != nil || utmCampaign != nil || 
              utmTerm != nil || utmContent != nil || utmXData != nil else {
            return nil
        }
        
        self.source = utmSource
        self.medium = utmMedium
        self.campaign = utmCampaign
        self.term = utmTerm
        self.content = utmContent
        self.x_data = utmXData
        self.capturedAt = Date()
        self.captureType = captureType
    }
    
    /// Convert to dictionary for analytics/tracking
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "captured_at": ISO8601DateFormatter().string(from: capturedAt),
            "capture_type": captureType.rawValue
        ]
        
        if let source = source { dict["utm_source"] = source }
        if let medium = medium { dict["utm_medium"] = medium }
        if let campaign = campaign { dict["utm_campaign"] = campaign }
        if let term = term { dict["utm_term"] = term }
        if let content = content { dict["utm_content"] = content }
        if let x_data = x_data { dict["utm_x_data"] = x_data }
        
        return dict
    }
    
    /// Check if this has any UTM values
    public var hasValues: Bool {
        return source != nil || medium != nil || campaign != nil || term != nil || content != nil || x_data != nil
    }
}
