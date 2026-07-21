import WebKit

/// A live ad decoupled from any BaseAdView instance: the rendered WKWebView
/// plus its JS bridge, tracking state, and creative metadata. When SwiftUI
/// discards a BaseAdView (e.g. `.id()` churn, screen re-creation) or a
/// covered screen gets a brand-new AdView instance on return, the session
/// survives and the same placement adopts it instead of re-fetching.
///
/// Main-thread only: mirrors WKWebView's own main-thread confinement. Every
/// call site is already on main (BaseAdView's lifecycle/loadAd methods).
final class AdSession {
    let webView: WKWebView
    let jsInterface: JsBridge
    let metaData: String
    let mediaType: String?

    /// The BaseAdView currently presenting this session. Weak: the store is
    /// not what keeps a host alive (the normal view hierarchy already does,
    /// for as long as the host is genuinely still around), and a strong
    /// reference here would only risk pinning a whole BaseAdView+WKWebView
    /// graph in memory forever if a cleanup path is ever missed - Swift has
    /// no GC to fall back on the way Android's Kotlin `var` does.
    weak var hostView: BaseAdView?

    init(
        webView: WKWebView,
        jsInterface: JsBridge,
        metaData: String,
        mediaType: String?,
        hostView: BaseAdView?
    ) {
        self.webView = webView
        self.jsInterface = jsInterface
        self.metaData = metaData
        self.mediaType = mediaType
        self.hostView = hostView
    }
}

/// Registry of live ad sessions keyed by "adUnitId|placement", so a session
/// is resumed only when the same screen/slot loads the same ad unit again.
/// No TTL/eviction - purely event-driven removal (explicit destroy(),
/// removeIfHosts() during teardown, or a superseding put()).
enum AdSessionStore {
    private static var sessions: [String: AdSession] = [:]

    static func put(key: String, session: AdSession) {
        sessions[key] = session
    }

    static func get(key: String) -> AdSession? {
        sessions[key]
    }

    static func remove(key: String) {
        sessions.removeValue(forKey: key)
    }

    /// Removes the session only if it is still backed by the given WebView -
    /// guards the race where a new session already overwrote this key before
    /// the old WebView's async destroy runs.
    static func removeIfHosts(key: String, webView: WKWebView) {
        if sessions[key]?.webView === webView {
            sessions.removeValue(forKey: key)
        }
    }
}
