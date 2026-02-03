import Foundation

/// Manages UTM parameter tracking for install attribution and deeplink campaigns
public final class UTMTracker {
    
    // MARK: - Singleton
    public static let shared = UTMTracker()
    
    // MARK: - Constants
    private let defaults = UserDefaults.standard
    private let FIRST_INSTALL_UTM_KEY = "adgeist_first_install_utm"
    private let LAST_DEEPLINK_UTM_KEY = "adgeist_last_deeplink_utm"
    private let FIRST_LAUNCH_FLAG_KEY = "adgeist_has_launched"
    private let ALL_UTM_HISTORY_KEY = "adgeist_utm_history"
    private let MAX_HISTORY_COUNT = 50
    
    // MARK: - Properties
    private var firstInstallUTM: UTMParameters?
    private var lastDeeplinkUTM: UTMParameters?
    private var utmHistory: [UTMParameters] = []
    private var utmAnalytics: UTMAnalytics?
    
    private let lock = NSLock()
    
    // MARK: - Initialization
    private init() {
        loadPersistedUTMData()
    }
    
    /// Initialize analytics integration with AdgeistCore
    /// Called automatically by AdgeistCore during initialization
    internal func initializeAnalytics(adgeistCore: AdgeistCore) {
        lock.lock()
        defer { lock.unlock() }
        
        self.utmAnalytics = UTMAnalytics(adgeistCore: adgeistCore)
        print("AdgeistKit: UTM analytics initialized")
    }
    
    // MARK: - Public Methods
    
    /// Track UTM parameters from first app install/launch
    /// Should be called early in app lifecycle, typically in AppDelegate or App struct
    public func trackInstallIfNeeded(url: URL? = nil) {
        lock.lock()
        let hasLaunched = defaults.bool(forKey: FIRST_LAUNCH_FLAG_KEY)
        lock.unlock()
        
        if !hasLaunched {
            // First install/launch
            var utmParams: UTMParameters?
            
            if let url = url {
                // Try to extract UTM from install URL if available
                utmParams = UTMParameters(url: url, captureType: .install)
            }
            
            // If no UTM found but this is first launch, create empty record
            if utmParams == nil {
                utmParams = UTMParameters(captureType: .install)
            }
            
            if let params = utmParams {
                lock.lock()
                firstInstallUTM = params
                saveFirstInstallUTM(params)
                addToHistory(params)
                lock.unlock()
                
                print("AdgeistKit: First install UTM tracked - \(params.toDictionary())")
                
                // Send install attribution event
                utmAnalytics?.sendInstallAttributionEvent(utmParameters: params.hasValues ? params : nil)
                
                // Send VISIT event if UTM parameters exist
                if params.hasValues {
                    utmAnalytics?.sendVisitEvent(utmParameters: params)
                }
            }
            
            lock.lock()
            defaults.set(true, forKey: FIRST_LAUNCH_FLAG_KEY)
            lock.unlock()
        }
    }
    
    /// Track UTM parameters from a deeplink
    /// Call this when your app handles a deeplink or universal link
    public func trackDeeplink(url: URL) {
        guard let utmParams = UTMParameters(url: url, captureType: .deeplink) else {
            print("AdgeistKit: No UTM parameters found in deeplink: \(url)")
            return
        }
        
        lock.lock()
        let previousUTM = lastDeeplinkUTM
        lastDeeplinkUTM = utmParams
        saveLastDeeplinkUTM(utmParams)
        addToHistory(utmParams)
        lock.unlock()
        
        print("AdgeistKit: Deeplink UTM tracked - \(utmParams.toDictionary())")
        
        // Send analytics events
        utmAnalytics?.sendVisitEvent(utmParameters: utmParams)
        utmAnalytics?.sendDeeplinkEvent(utmParameters: utmParams, url: url)
        
        if previousUTM != nil && previousUTM != utmParams {
            utmAnalytics?.sendUTMUpdateEvent(previousUTM: previousUTM, newUTM: utmParams)
        }
    }
    
    /// Track UTM parameters from a universal link
    public func trackUniversalLink(url: URL) {
        guard let utmParams = UTMParameters(url: url, captureType: .universal) else {
            print("AdgeistKit: No UTM parameters found in universal link: \(url)")
            return
        }
        
        lock.lock()
        let previousUTM = lastDeeplinkUTM
        lastDeeplinkUTM = utmParams
        saveLastDeeplinkUTM(utmParams)
        addToHistory(utmParams)
        lock.unlock()
        
        print("AdgeistKit: Universal link UTM tracked - \(utmParams.toDictionary())")
        
        // Send analytics events
        utmAnalytics?.sendVisitEvent(utmParameters: utmParams)
        utmAnalytics?.sendDeeplinkEvent(utmParameters: utmParams, url: url)
        
        if previousUTM != nil && previousUTM != utmParams {
            utmAnalytics?.sendUTMUpdateEvent(previousUTM: previousUTM, newUTM: utmParams)
        }
    }
    
    /// Get UTM parameters from first install
    public func getFirstInstallUTM() -> UTMParameters? {
        lock.lock()
        defer { lock.unlock() }
        return firstInstallUTM
    }
    
    /// Get the most recent deeplink/universal link UTM parameters
    public func getLastDeeplinkUTM() -> UTMParameters? {
        lock.lock()
        defer { lock.unlock() }
        return lastDeeplinkUTM
    }
    
    /// Get all UTM parameters (most relevant first)
    /// Priority: Last deeplink > First install
    public func getAllUTMParameters() -> [String: Any] {
        lock.lock()
        defer { lock.unlock() }
        
        var utmData: [String: Any] = [:]
        
        if let lastDeeplink = lastDeeplinkUTM {
            utmData["last_deeplink"] = lastDeeplink.toDictionary()
        }
        
        if let firstInstall = firstInstallUTM {
            utmData["first_install"] = firstInstall.toDictionary()
        }
        
        return utmData
    }
    
    /// Get the most recent UTM parameters (prefers deeplink over install)
    public func getCurrentUTMParameters() -> UTMParameters? {
        lock.lock()
        defer { lock.unlock() }
        
        return lastDeeplinkUTM ?? firstInstallUTM
    }
    
    /// Get UTM history (most recent first)
    public func getUTMHistory() -> [UTMParameters] {
        lock.lock()
        defer { lock.unlock() }
        return utmHistory
    }
    
    /// Clear all UTM data (useful for testing)
    public func clearAllUTMData() {
        lock.lock()
        defer { lock.unlock() }
        
        firstInstallUTM = nil
        lastDeeplinkUTM = nil
        utmHistory.removeAll()
        
        defaults.removeObject(forKey: FIRST_INSTALL_UTM_KEY)
        defaults.removeObject(forKey: LAST_DEEPLINK_UTM_KEY)
        defaults.removeObject(forKey: ALL_UTM_HISTORY_KEY)
        defaults.removeObject(forKey: FIRST_LAUNCH_FLAG_KEY)
        
        print("AdgeistKit: All UTM data cleared")
    }
    
    // MARK: - Private Methods
    
    private func loadPersistedUTMData() {
        // Load first install UTM
        if let data = defaults.data(forKey: FIRST_INSTALL_UTM_KEY),
           let params = try? JSONDecoder().decode(UTMParameters.self, from: data) {
            firstInstallUTM = params
        }
        
        // Load last deeplink UTM
        if let data = defaults.data(forKey: LAST_DEEPLINK_UTM_KEY),
           let params = try? JSONDecoder().decode(UTMParameters.self, from: data) {
            lastDeeplinkUTM = params
        }
        
        // Load history
        if let data = defaults.data(forKey: ALL_UTM_HISTORY_KEY),
           let history = try? JSONDecoder().decode([UTMParameters].self, from: data) {
            utmHistory = history
        }
    }
    
    private func saveFirstInstallUTM(_ params: UTMParameters) {
        if let data = try? JSONEncoder().encode(params) {
            defaults.set(data, forKey: FIRST_INSTALL_UTM_KEY)
        }
    }
    
    private func saveLastDeeplinkUTM(_ params: UTMParameters) {
        if let data = try? JSONEncoder().encode(params) {
            defaults.set(data, forKey: LAST_DEEPLINK_UTM_KEY)
        }
    }
    
    private func addToHistory(_ params: UTMParameters) {
        // Add to beginning (most recent first)
        utmHistory.insert(params, at: 0)
        
        // Limit history size
        if utmHistory.count > MAX_HISTORY_COUNT {
            utmHistory = Array(utmHistory.prefix(MAX_HISTORY_COUNT))
        }
        
        // Persist
        if let data = try? JSONEncoder().encode(utmHistory) {
            defaults.set(data, forKey: ALL_UTM_HISTORY_KEY)
        }
    }
}
