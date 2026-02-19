import Foundation

public class AdRequest {
    public let isTestMode: Bool
    
    private init(builder: AdRequestBuilder) {
        self.isTestMode = builder.testMode
    }
    
    public class AdRequestBuilder {
        internal var testMode: Bool = false
        
        public init() {}
        
        @discardableResult
        public func setTestMode(_ testMode: Bool) -> AdRequestBuilder {
            self.testMode = testMode
            return self
        }
        
        public func build() -> AdRequest {
            return AdRequest(builder: self)
        }
    }
    
    public func toJson() -> [String: Any] {
        var json: [String: Any] = [:]
        json["testMode"] = isTestMode
        return json
    }
}

extension AdRequest: CustomStringConvertible {
    public var description: String {
        return "AdRequest(testMode=\(isTestMode))"
    }
}
