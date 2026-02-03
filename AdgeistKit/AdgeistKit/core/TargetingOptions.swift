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
        
        // Include UTM parameters if available
        let utmData = UTMTracker.shared.getAllUTMParameters()
        if !utmData.isEmpty {
            targetingInfo["utm"] = utmData
        }
        
        return targetingInfo
    }
}
