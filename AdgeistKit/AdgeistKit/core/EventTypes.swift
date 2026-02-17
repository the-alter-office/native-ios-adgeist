import Foundation

/// Event types for UTM tracking and analytics
public struct EventTypes {
    /// User visited via UTM link
    public static let VISIT = "VISIT"
    
    /// App installed with UTM attribution
    public static let INSTALL = "INSTALL"
    
    /// Session duration event (sent on app backgrounding)
    public static let SESSION_DURATION = "SESSION_DURATION"
}
