import Foundation

/// Handles tracking and persistence of UTM parameters from install referrer and deeplinks
public final class UTMTracker {
    
    // MARK: - Singleton
    public static let shared = UTMTracker()
    
    // MARK: - Constants
    private let TAG = "UTMTracker"
    private let defaults = UserDefaults.standard
    private let KEY_UTM_SOURCE = "utm_source"
    private let KEY_UTM_CAMPAIGN = "utm_campaign"
    private let KEY_UTM_DATA = "utm_data"
    private let KEY_SESSION_ID = "session_id"
    private let KEY_FIRST_LAUNCH = "first_launch"
    
    // MARK: - Properties
    private var utmAnalytics: UTMAnalytics?
    private let lock = NSLock()
    
    // MARK: - Initialization
    private init() {
        // Initialization logic
    }
    
    /// Initialize analytics integration
    /// Called automatically by AdgeistCore during initialization
    internal func initializeAnalytics(bidRequestBackendDomain: String) {
        lock.lock()
        defer { lock.unlock() }
        
        self.utmAnalytics = UTMAnalytics(bidRequestBackendDomain: bidRequestBackendDomain)
        print("\(TAG): UTM analytics initialized")
    }
    
    // MARK: - Public Methods
    
    /// Track UTM parameters from a deeplink URI
    public func trackFromDeeplink(url: URL) {
        guard let utmParams = UTMParameters(url: url) else {
            print("\(TAG): No UTM parameters found in deeplink: \(url)")
            return
        }
        
        saveUtmParameters(utmParams, eventType: "VISIT")
        print("\(TAG): UTM parameters tracked from deeplink: \(utmParams.toDictionary())")
    }
    
    /// Initialize and track first launch
    /// Uses URL if provided (for install attribution)
    /// Note: iOS doesn't have an equivalent to Android's Install Referrer API
    public func initializeInstallReferrer(url: URL? = nil) {
        lock.lock()
        let isFirstLaunch = defaults.bool(forKey: KEY_FIRST_LAUNCH)
        lock.unlock()
        
        if !isFirstLaunch {
            // Mark first launch as complete
            lock.lock()
            defaults.set(true, forKey: KEY_FIRST_LAUNCH)
            lock.unlock()
            
            // Try to extract UTM from install URL if available
            if let url = url, let utmParams = UTMParameters(url: url) {
                saveUtmParameters(utmParams, eventType: "INSTALL")
                print("\(TAG): First launch UTM tracked from URL: \(utmParams.toDictionary())")
            } else {
                print("\(TAG): First launch tracked (no UTM parameters)")
            }
        }
    }
    
    /// Get stored UTM parameters
    public func getUtmParameters() -> UTMParameters? {
        lock.lock()
        defer { lock.unlock() }
        
        let source = defaults.string(forKey: KEY_UTM_SOURCE)
        let campaign = defaults.string(forKey: KEY_UTM_CAMPAIGN)
        let data = defaults.string(forKey: KEY_UTM_DATA)
        let sessionId = defaults.string(forKey: KEY_SESSION_ID)
        
        let params = UTMParameters(source: source, campaign: campaign, data: data, sessionId: sessionId)
        return params.hasData() ? params : nil
    }
    
    /// Clear all stored UTM parameters
    public func clearUtmParameters() {
        lock.lock()
        defer { lock.unlock() }
        
        defaults.removeObject(forKey: KEY_UTM_SOURCE)
        defaults.removeObject(forKey: KEY_UTM_CAMPAIGN)
        defaults.removeObject(forKey: KEY_UTM_DATA)
        defaults.removeObject(forKey: KEY_SESSION_ID)
        
        print("\(TAG): UTM parameters cleared")
    }
    
    // MARK: - Private Methods
    
    /// Generates a unique session ID
    private func generateSessionId() -> String {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let uuid = UUID().uuidString.prefix(9)
        return "\(timestamp)-\(uuid)"
    }
    
    /// Save UTM parameters to UserDefaults
    private func saveUtmParameters(_ params: UTMParameters, eventType: String) {
        let sessionId = generateSessionId()
        
        lock.lock()
        if let source = params.source {
            defaults.set(source, forKey: KEY_UTM_SOURCE)
        }
        if let campaign = params.campaign {
            defaults.set(campaign, forKey: KEY_UTM_CAMPAIGN)
        }
        if let data = params.data {
            defaults.set(data, forKey: KEY_UTM_DATA)
        }
        defaults.set(sessionId, forKey: KEY_SESSION_ID)
        lock.unlock()
        
        // Send UTM data to backend
        let paramsWithSession = UTMParameters(
            source: params.source,
            campaign: params.campaign,
            data: params.data,
            sessionId: sessionId
        )
        sendUtmDataToBackend(paramsWithSession, eventType: eventType)
    }
    
    /// Send UTM parameters to backend API
    private func sendUtmDataToBackend(_ params: UTMParameters, eventType: String) {
        utmAnalytics?.sendUtmData(params, eventType: eventType, onComplete: nil)
    }
}
