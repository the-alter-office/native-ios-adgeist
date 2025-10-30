import Foundation

public final class TargetingOptions {
    private let deviceMeta: DeviceMeta
    
    public init() {
        self.deviceMeta = DeviceMeta()
    }
    
    /// Returns targeting info with meta + IP address
    public func getTargetingInfo() -> [String: Any] {
        let meta = deviceMeta.getAllDeviceInfo()
        
        return [
            "meta": meta,
        ]
    }
}
