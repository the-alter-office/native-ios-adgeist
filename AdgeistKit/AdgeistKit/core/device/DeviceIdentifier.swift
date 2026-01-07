import Foundation
import AppTrackingTransparency
import AdSupport
import Security

@available(iOS, introduced: 11.0)
public final class DeviceIdentifier {    
    private func getAdvertisingID(completion: @escaping (String?) -> Void) {
        // Check if advertising tracking is available (not available on simulator)
        guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {
            completion(nil)
            return
        }
        
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                        completion(idfa)
                    } else {
                        completion(nil)
                    }
                }
            }
        } else {
            // For iOS < 14
            let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            completion(idfa)
        }
    }
    
    public func getDeviceIdentifier(completion: @escaping (String) -> Void) {
        getAdvertisingID { [weak self] idfa in
            DispatchQueue.main.async {
                guard let self = self else {
                    completion("00000000-0000-0000-0000-000000000000")
                    return
                }
                
                // Check if we got a valid IDFA
                if let idfa = idfa, !idfa.isEmpty, idfa != "00000000-0000-0000-0000-000000000000" {
                    print(idfa , "idfa")
                    completion(idfa)
                    return
                }
                
                // Return default zeros IDFA if not available
                completion("00000000-0000-0000-0000-000000000000")
            }
        }
    }
}

