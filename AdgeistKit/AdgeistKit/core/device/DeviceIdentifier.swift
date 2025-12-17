import Foundation
import AppTrackingTransparency
import AdSupport
import Security

@available(iOS, introduced: 11.0)
public final class DeviceIdentifier {
    // Keychain key for storing the generated UUID
    private static let keychainKey = "com.adgeist.app.install.id"
    
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
    
    private func getVendorID() -> String? {
        // Use ProcessInfo instead of UIDevice
        if let vendorID = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] {
            return vendorID
        }
        
        return getDeviceHardwareUUID()
    }
    
    private func getDeviceHardwareUUID() -> String? {
        // This is a less reliable method than identifierForVendor
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.isEmpty ? nil : identifier
    }
    
    private func getOrCreateAppInstallID() -> String {
        if let existingID = loadFromKeychain() {
            return existingID
        }
        
        let newID = UUID().uuidString
        saveToKeychain(value: newID)
        return newID
    }
    
    private func saveToKeychain(value: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: DeviceIdentifier.keychainKey,
            kSecValueData as String: value.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: DeviceIdentifier.keychainKey,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    public func getDeviceIdentifier(completion: @escaping (String) -> Void) {
        getAdvertisingID { [weak self] idfa in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Check if we got a valid IDFA
                if let idfa = idfa, !idfa.isEmpty, idfa != "00000000-0000-0000-0000-000000000000" {
                    print(idfa , "idfa")
                    completion(idfa)
                    return
                }
                
                // Fallback to Vendor ID alternative
                if let vendorID = self.getVendorID() {
                    print(vendorID , "vendor id")
                    completion(vendorID)
                    return
                }
                
                // Final fallback to generated UUID
                let generatedID = self.getOrCreateAppInstallID()
                print(generatedID , "generated id")
                completion(generatedID)
            }
        }
    }
    
    public func clearGeneratedID() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: DeviceIdentifier.keychainKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

