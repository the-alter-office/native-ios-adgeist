import Foundation

public final class TargetingOptions {
    private let deviceMeta: DeviceMeta
    
    public init() {
        self.deviceMeta = DeviceMeta()
    }
    
    public func getTargetingInfo() -> [String: Any] {
        let meta = deviceMeta.getAllDeviceInfo()
        
        var targetingInfo: [String: Any] = [
            "meta": meta,
        ]
        
        return targetingInfo
    }
}
