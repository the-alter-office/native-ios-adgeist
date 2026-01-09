import Foundation

public final class AdgeistCore {
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
    public let apiKey: String

    public let deviceIdentifier: DeviceIdentifier
    public let networkUtils: NetworkUtils
    public let deviceMeta: DeviceMeta
    public var targetingInfo: [String: Any]?

    private var userDetails: UserDetails?
    private let cdpClient: CdpClient

    private static let bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJraXNob3JlIiwiaWF0IjoxNzU0Mzc1NzIwLCJuYmYiOjE3NTQzNzU3MjAsImV4cCI6MTc1Nzk3NTcyMCwianRpIjoiOTdmNTI1YjAtM2NhNy00MzQwLTlhOGItZDgwZWI2ZjJmOTAzIiwicm9sZSI6ImFkbWluIiwic2NvcGUiOiJpbmdlc3QiLCJwbGF0Zm9ybSI6Im1vYmlsZSIsImNvbXBhbnlfaWQiOiJraXNob3JlIiwiaXNzIjoiQWRHZWlzdC1DRFAifQ.IYQus53aQETqOaQzEED8L51jwKRN3n-Oq-M8jY_ZSaw"
    
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
        customAdgeistAppID: String? = nil
    ) {
        self.consentGiven = defaults.bool(forKey: KEY_CONSENT)
        self.bidRequestBackendDomain = bidRequestBackendDomain
        
        self.deviceIdentifier = DeviceIdentifier()
        self.networkUtils = NetworkUtils()
        self.deviceMeta = DeviceMeta()
        
        self.cdpClient = CdpClient(deviceIdentifier: self.deviceIdentifier, bearerToken: AdgeistCore.bearerToken)
        self.targetingInfo = TargetingOptions().getTargetingInfo()

        let bundle = Bundle.main
        func getMetaValue(_ key: String) -> String? {
            let value = bundle.object(forInfoDictionaryKey: key) as? String
            print("DEBUG: Value found for key '\(key)': \(String(describing: value))")
            return value
        }

        self.packageOrBundleID = customPackageOrBundleID ?? bundle.bundleIdentifier ?? ""
        self.adgeistAppID = customAdgeistAppID ?? getMetaValue("ADGEIST_APP_ID") ?? ""
        self.apiKey = getMetaValue("ADGEIST_API_KEY") ?? ""
    }
    
    public static func initialize(
        customBidRequestBackendDomain: String? = nil,
        customPackageOrBundleID: String? = nil,
        customAdgeistAppID: String? = nil
    ) -> AdgeistCore {
        lock.lock()
        defer { lock.unlock() }
        
        print("DEBUG: Initializing AdgeistCore \(getDefaultDomain())")
        if _instance == nil {
            _instance = AdgeistCore(
                bidRequestBackendDomain: customBidRequestBackendDomain ?? getDefaultDomain(),
                customPackageOrBundleID: customPackageOrBundleID,
                customAdgeistAppID: customAdgeistAppID
            )
        }
        return _instance!
    }
    
    public static func destroy() {
        lock.lock()
        defer { lock.unlock() }
        _instance = nil
    }
    
    public static func getInstance() -> AdgeistCore {
        guard let instance = _instance else {
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
            self.cdpClient.sendEventToCdp(fullEvent, consentGiven: self.consentGiven)
        }
    }
}
