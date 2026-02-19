import Foundation

public class AnalyticsRequestDEPRECATED {
    // Required
    public let adUnitID: String
    public let isTestMode: Bool
    
    public let buyType: String?
    private let campaignID: String?
    private let bidID: String?
    private let metaData: String?
    
    // Optional
    private let eventType: String?
    private let renderTime: Float
    private let visibilityRatio: Float
    private let scrollDepth: Float
    private let viewTime: Float
    private let timeToVisible: Float
    private let totalViewTime: Float
    private let totalPlaybackTime: Float
    
    private init(builder: AnalyticsRequestBuilderDEPRECATED) {
        self.adUnitID = builder.adUnitID
        self.isTestMode = builder.isTestMode
        
        self.eventType = builder.eventType
        self.renderTime = builder.renderTime
        self.visibilityRatio = builder.visibilityRatio
        self.scrollDepth = builder.scrollDepth
        self.viewTime = builder.viewTime
        self.timeToVisible = builder.timeToVisible
        self.totalViewTime = builder.totalViewTime
        self.totalPlaybackTime = builder.totalPlaybackTime
        
        self.buyType = builder.buyType
        self.campaignID = builder.campaignID
        self.bidID = builder.bidID
        self.metaData = builder.metaData
    }
    
    public class AnalyticsRequestBuilderDEPRECATED {
        internal let adUnitID: String
        internal let isTestMode: Bool
        
        internal var buyType: String?
        internal var campaignID: String?
        internal var bidID: String?
        internal var metaData: String?
        
        // Optional
        internal var eventType: String?
        internal var renderTime: Float = 0.0
        internal var visibilityRatio: Float = 0.0
        internal var scrollDepth: Float = 0.0
        internal var viewTime: Float = 0.0
        internal var timeToVisible: Float = 0.0
        internal var totalViewTime: Float = 0.0
        internal var totalPlaybackTime: Float = 0.0
        
        public init(adUnitID: String, isTestMode: Bool) {
            self.adUnitID = adUnitID
            self.isTestMode = isTestMode
        }
        
        @discardableResult
        public func buildCPMRequest(campaignID: String, bidID: String) -> AnalyticsRequestBuilderDEPRECATED {
            self.buyType = "CPM"
            self.campaignID = campaignID
            self.bidID = bidID
            return self
        }
        
        @discardableResult
        public func buildFIXEDRequest(metaData: String) -> AnalyticsRequestBuilderDEPRECATED {
            self.buyType = "FIXED"
            self.metaData = metaData
            return self
        }
        
        @discardableResult
        public func trackImpression(renderTime: Float) -> AnalyticsRequestBuilderDEPRECATED {
            self.eventType = "IMPRESSION"
            self.renderTime = renderTime
            return self
        }
        
        @discardableResult
        public func trackViewableImpression(
            timeToVisible: Float,
            scrollDepth: Float,
            visibilityRatio: Float,
            viewTime: Float
        ) -> AnalyticsRequestBuilderDEPRECATED {
            self.eventType = "VIEW"
            self.timeToVisible = timeToVisible
            self.scrollDepth = scrollDepth
            self.visibilityRatio = visibilityRatio
            self.viewTime = viewTime
            return self
        }
        
        @discardableResult
        public func trackClick() -> AnalyticsRequestBuilderDEPRECATED {
            self.eventType = "CLICK"
            return self
        }
        
        @discardableResult
        public func trackTotalViewTime(totalViewTime: Float) -> AnalyticsRequestBuilderDEPRECATED {
            self.eventType = "TOTAL_VIEW_TIME"
            self.totalViewTime = totalViewTime
            return self
        }
        
        @discardableResult
        public func trackTotalPlaybackTime(totalPlaybackTime: Float) -> AnalyticsRequestBuilderDEPRECATED {
            self.eventType = "TOTAL_PLAYBACK_TIME"
            self.totalPlaybackTime = totalPlaybackTime
            return self
        }
        
        public func build() -> AnalyticsRequestDEPRECATED {
            return AnalyticsRequestDEPRECATED(builder: self)
        }
    }
    
    public func toJson() -> [String: Any] {
        var json: [String: Any] = [:]
        
        if buyType == "FIXED" {
            json["metaData"] = metaData
            json["isTest"] = isTestMode
            json["type"] = eventType
        } else {
            json["winningBidId"] = bidID
            json["campaignId"] = campaignID
            json["eventType"] = eventType
        }
        
        switch eventType {
        case "IMPRESSION":
            json["renderTime"] = renderTime
        case "VIEW":
            json["timeToVisible"] = timeToVisible
            json["scrollDepth"] = scrollDepth
            json["visibilityRatio"] = visibilityRatio
            json["viewTime"] = viewTime
        case "TOTAL_VIEW_TIME":
            json["totalViewTime"] = totalViewTime
        case "TOTAL_PLAYBACK_TIME":
            json["totalPlaybackTime"] = totalPlaybackTime
        case "CLICK":
            break
        default:
            break
        }
        
        return json
    }
    
    public func toJsonData() throws -> Data {
        return try JSONSerialization.data(withJSONObject: toJson(), options: [])
    }
}
