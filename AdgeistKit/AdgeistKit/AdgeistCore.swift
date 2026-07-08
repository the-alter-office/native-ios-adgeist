import Foundation
import AppTrackingTransparency

public final class AdgeistCore {
    private static let TAG = "AdgeistCore"
    public static var shared: AdgeistCore {
        guard let instance = _instance else {
            fatalError("AdgeistCore is not initialized. Call initialize(customDomain:) first.")
        }
        return instance
    }
    
    private static var _instance: AdgeistCore?
    private static let lock = NSLock()
    
    private let defaults = UserDefaults.standard
    private let PREFS_NAME = "AdgeistPrefs" 
    private let KEY_CONSENT = "adgeist_consent"
    private var consentGiven: Bool = false

    public let bidRequestBackendDomain: String
    public let packageOrBundleID: String
    public let adgeistAppID: String
    public let version: String

    public let deviceIdentifier: DeviceIdentifier
    public let networkUtils: NetworkUtils
    public let deviceMeta: DeviceMeta
    public var targetingInfo: [String: Any]?

    private var userDetails: UserDetails?

    private static func getDefaultDomain() -> String {
        let frameworkBundle = Bundle(for: AdgeistCore.self)
                        
        if let baseURL = frameworkBundle.object(forInfoDictionaryKey: "BASE_API_URL") as? String {
            print("DEBUG: Using config domain for AdgeistCore: \(baseURL)")
            return baseURL
        }

        return "https://beta.v2.bg-services.adgeist.ai"
    }

    private init(
        bidRequestBackendDomain: String,
        customPackageOrBundleID: String? = nil,
        customAdgeistAppID: String? = nil,
        customVersioning: String? = nil
    ) {
        // Key debug: Initialization start
        print("[AdgeistCore] Initializing...")
        do {
            self.consentGiven = defaults.bool(forKey: KEY_CONSENT)
            self.bidRequestBackendDomain = bidRequestBackendDomain
            self.deviceIdentifier = DeviceIdentifier()
            self.networkUtils = NetworkUtils()
            self.deviceMeta = DeviceMeta()
            self.targetingInfo = TargetingOptions().getTargetingInfo()

            let bundle = Bundle.main
            func getMetaValue(_ key: String) -> String? {
                return bundle.object(forInfoDictionaryKey: key) as? String
            }

            self.packageOrBundleID = customPackageOrBundleID ?? bundle.bundleIdentifier ?? ""
            self.adgeistAppID = customAdgeistAppID ?? getMetaValue("ADGEIST_APP_ID") ?? ""

            // Get version from framework bundle
            let frameworkBundle = Bundle(for: AdgeistCore.self)
            let versionName = frameworkBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
            let versionSuffix = frameworkBundle.object(forInfoDictionaryKey: "VERSION_SUFFIX") as? String ?? ""
            self.version = customVersioning ?? "IOS-\(versionName)-\(versionSuffix)"

            self.requestTrackingPermission()

            if self.adgeistAppID.isEmpty {
                print("[AdgeistCore] WARNING: adgeistAppID is empty. Set ADGEIST_APP_ID in Info.plist")
            }
        } catch {
            print("[AdgeistCore] CRITICAL: Initialization failed: \(error)")
            fatalError("AdgeistCore initialization failed. See logs for details. \(error)")
        }
    }
    
    public static func initialize(
        customBidRequestBackendDomain: String? = nil,
        customPackageOrBundleID: String? = nil,
        customAdgeistAppID: String? = nil,
        customVersioning: String? = nil
    ) -> AdgeistCore {
        lock.lock()
        defer { lock.unlock() }
        if _instance == nil {
            do {
                _instance = AdgeistCore(
                    bidRequestBackendDomain: customBidRequestBackendDomain ?? getDefaultDomain(),
                    customPackageOrBundleID: customPackageOrBundleID,
                    customAdgeistAppID: customAdgeistAppID,
                    customVersioning: customVersioning
                )
                print("[AdgeistCore] Initialized successfully")
            } catch {
                print("[AdgeistCore] CRITICAL: Initialization failed: \(error)")
                fatalError("AdgeistCore initialization failed. See logs for details. \(error)")
            }
        }
        return _instance!
    }
    
    public static func destroy() {
        lock.lock()
        defer { lock.unlock() }
        print("[AdgeistCore] Destroyed")
        _instance = nil
    }
    
    public static func getInstance() -> AdgeistCore {
        guard let instance = _instance else {
            print("[AdgeistCore] ERROR: Not initialized")
            fatalError("AdgeistCore is not initialized. Call initialize(...) first.")
        }
        return instance
    }
    
    public func setUserDetails(_ details: UserDetails) {
        objc_sync_enter(self)
        self.userDetails = details
        objc_sync_exit(self)
    }

    public func updateConsentStatus(_ consentGiven: Bool) {
        self.consentGiven = consentGiven
        defaults.set(consentGiven, forKey: KEY_CONSENT)
    }

    public func getConsentStatus() -> Bool {
        return consentGiven
    }

    public func getCreative() -> FetchCreative {
        return FetchCreative(adgeistCore: self)
    }
    
    public func postCreativeAnalytics() -> CreativeAnalytics {
        return CreativeAnalytics(adgeistCore: self)
    }

    public func logEvent(_ event: Event) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            var parameters: [String: Any] = event.eventProperties ?? [:]
            if let userDetails = self.userDetails {
                parameters["userDetails"] = userDetails.toDictionary()
            }
            let fullEvent = Event(eventType: event.eventType, eventProperties: parameters)
        }
    }

    private func requestTrackingPermission() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    print("[AdgeistCore] Tracking permission granted")
                case .denied:
                    print("[AdgeistCore] Tracking permission denied")
                case .restricted:
                    print("[AdgeistCore] Tracking permission restricted")
                case .notDetermined:
                    print("[AdgeistCore] Tracking permission not determined")
                @unknown default:
                    print("[AdgeistCore] Unknown tracking permission status")
                }
            }
        }
    }
}
