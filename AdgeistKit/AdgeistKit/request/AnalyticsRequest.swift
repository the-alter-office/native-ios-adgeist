import Foundation

public class AnalyticsRequest {
    // Required
    private let metaData: String

    // Optional
    private let type: String?
    private let visibilityRatio: Float
    private let scrollDepth: Float
    private let viewTime: Int64
    private let timeToVisible: Int64

    private init(builder: AnalyticsRequestBuilder) {
        self.metaData = builder.metaData
        self.type = builder.type
        self.visibilityRatio = builder.visibilityRatio
        self.scrollDepth = builder.scrollDepth
        self.viewTime = builder.viewTime
        self.timeToVisible = builder.timeToVisible
    }

    public class AnalyticsRequestBuilder {
        // Required
        internal let metaData: String

        // Optional
        internal var type: String?
        internal var visibilityRatio: Float = 0.0
        internal var scrollDepth: Float = 0.0
        internal var viewTime: Int64 = 0
        internal var timeToVisible: Int64 = 0

        public init(metaData: String) {
            self.metaData = metaData
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

        public func build() -> AnalyticsRequest {
            return AnalyticsRequest(builder: self)
        }
    }
    
    public func toJson() -> [String: Any] {
        var json: [String: Any] = [:]
        
        json["metaData"] = metaData
        json["type"] = type
        
        switch type {
        case "VIEW":
            json["timeToVisible"] = timeToVisible
            json["scrollDepth"] = Double(scrollDepth)
            json["visibilityRatio"] = Double(visibilityRatio)
            json["viewTime"] = viewTime

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
