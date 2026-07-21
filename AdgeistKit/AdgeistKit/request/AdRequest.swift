import Foundation

public class AdRequest {
    private init(builder: AdRequestBuilder) {
    }

    public class AdRequestBuilder {
        public init() {}

        public func build() -> AdRequest {
            return AdRequest(builder: self)
        }
    }

    public func toJson() -> [String: Any] {
        let json: [String: Any] = [:]
        return json
    }
}

extension AdRequest: CustomStringConvertible {
    public var description: String {
        return "AdRequest()"
    }
}
