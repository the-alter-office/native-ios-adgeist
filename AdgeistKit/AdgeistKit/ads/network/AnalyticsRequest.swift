import Foundation

public class AnalyticsRequest {
    // Required
    private let metaData: String
    private let isTestMode: Bool
    
    // Optional
    private let type: String?
    private let renderTime: Int64
    private let visibilityRatio: Float
    private let scrollDepth: Float
    private let viewTime: Int64
    private let timeToVisible: Int64
    private let totalViewTime: Int64
    private let totalPlaybackTime: Int64
    
    private init(builder: AnalyticsRequestBuilder) {
        self.metaData = builder.metaData
        self.isTestMode = builder.isTestMode
        self.type = builder.type
        self.renderTime = builder.renderTime
        self.visibilityRatio = builder.visibilityRatio
        self.scrollDepth = builder.scrollDepth
        self.viewTime = builder.viewTime
        self.timeToVisible = builder.timeToVisible
        self.totalViewTime = builder.totalViewTime
        self.totalPlaybackTime = builder.totalPlaybackTime
    }
    
    public class AnalyticsRequestBuilder {
        // Required
        internal let metaData: String
        internal let isTestMode: Bool
        
        // Optional
        internal var type: String?
        internal var renderTime: Int64 = 0
        internal var visibilityRatio: Float = 0.0
        internal var scrollDepth: Float = 0.0
        internal var viewTime: Int64 = 0
        internal var timeToVisible: Int64 = 0
        internal var totalViewTime: Int64 = 0
        internal var totalPlaybackTime: Int64 = 0
        
        public init(metaData: String, isTestMode: Bool) {
            self.metaData = metaData
            self.isTestMode = isTestMode
        }
        
        @discardableResult
        public func trackImpression(renderTime: Int64) -> AnalyticsRequestBuilder {
            self.type = "IMPRESSION"
            self.renderTime = renderTime
            return self
        }
        
        @discardableResult
        public func trackViewableImpression(
            timeToVisible: Int64,
            scrollDepth: Float,
            visibilityRatio: Float,
            viewTime: Int64
        ) -> AnalyticsRequestBuilder {
            self.type = "VIEW"
            self.timeToVisible = timeToVisible
            self.scrollDepth = scrollDepth
            self.visibilityRatio = visibilityRatio
            self.viewTime = viewTime
            return self
        }
        
        @discardableResult
        public func trackClick() -> AnalyticsRequestBuilder {
            self.type = "CLICK"
            return self
        }
        
        @discardableResult
        public func trackTotalViewTime(totalViewTime: Int64) -> AnalyticsRequestBuilder {
            self.type = "TOTAL_VIEW_TIME"
            self.totalViewTime = totalViewTime
            return self
        }
        
        @discardableResult
        public func trackTotalPlaybackTime(totalPlaybackTime: Int64) -> AnalyticsRequestBuilder {
            self.type = "TOTAL_PLAYBACK_TIME"
            self.totalPlaybackTime = totalPlaybackTime
            return self
        }
        
        public func build() -> AnalyticsRequest {
            return AnalyticsRequest(builder: self)
        }
    }
    
    public func toJson() -> [String: Any] {
        var json: [String: Any] = [:]
        
        json["metaData"] = metaData
        json["isTestMode"] = isTestMode
        json["type"] = type
        
        switch type {
        case "IMPRESSION":
            json["renderTime"] = renderTime
            
        case "VIEW":
            json["timeToVisible"] = timeToVisible
            json["scrollDepth"] = Double(scrollDepth)
            json["visibilityRatio"] = Double(visibilityRatio)
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
}
