import UIKit
import WebKit

open class BaseAdView: UIView {

    private static let TAG = "BaseAdView"

    // MARK: - Ad configuration
    public var adSize: AdSize? = nil
    public var adUnitId: String = ""
    public var adType: AdType = .BANNER
    public var adIsResponsive: Bool = false
    public var isTestMode: Bool = false

    /// Stable identity of this ad slot; sessions are resumed only by the same
    /// placement. Auto-derived (accessibility identifier / host VC type) when
    /// left empty - see resolvePlacementKey().
    public var placementId: String = ""

    // MARK: - Creative metadata used by tracking
    public var metaData: String = ""
    public var mediaType: String? = nil

    public var listener: AdListener?

    // MARK: - Runtime state
    internal var webView: WKWebView?
    private var jsInterface: JsBridge?
    private var isLoading: Bool = false
    private var isDestroyed = false

    // MARK: - Ad session management
    private var activeSessionKey: String?
    private var pendingLoadWorkItem: DispatchWorkItem?

    // MARK: - Host destroy watcher
    private static var canariesAssociationKey: UInt8 = 0
    private var hostDestroyCanary: HostDestroyCanary?
    private weak var registeredHostVC: UIViewController?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }

    private func initialize() {
    }

    public func setAdListener(_ listener: AdListener?) {
        self.listener = listener
    }

    public func setAdDimension(_ adSize: AdSize) {
        self.adSize = adSize
        setNeedsLayout()
    }

    public var isCollapsible: Bool {
        return false
    }

    // MARK: - Loading and rendering

    /// Loads an ad with the specified AdRequest. This is the main entry point
    /// for publishers to request and display ads. If a live session already
    /// exists for this ad unit + placement, it is adopted instead of doing a
    /// fresh network fetch. If an ad is already loading, this call is ignored.
    public func loadAd(_ adRequest: AdRequest) {
        if isLoading {
            print("\(Self.TAG): loadAd ignored - ad is already loading")
            return
        }
        if adUnitId.isEmpty {
            print("\(Self.TAG): Ad unit ID is null or empty")
            listener?.onAdFailedToLoad("Ad unit ID is null or empty")
            return
        }

        if let key = sessionKey(), let session = AdSessionStore.get(key: key) {
            // Steal guard: never rip the ad out of another visible slot.
            let hostedElsewhereAndVisible = session.hostView !== self && session.hostView?.window != nil
            if !hostedElsewhereAndVisible {
                if session.hostView === self && webView != nil {
                    print("\(Self.TAG): loadAd ignored - this view is already presenting the live ad")
                    return
                }
                adoptSession(key: key, session: session)
                return
            }
            print("\(Self.TAG): Session '\(key)' is visible in another slot - fetching a new ad instead")
        }

        isLoading = true

        // isDestroyed is reset inside the delayed block, not here: safelyDestroyWebView()
        // sets it synchronously, so resetting earlier would immediately be undone and the
        // reload would silently never run.
        let needsCleanup = webView != nil
        if needsCleanup {
            safelyDestroyWebView()
        }

        pendingLoadWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.isDestroyed = false
            self.startAdLoad(adRequest)
        }
        pendingLoadWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + (needsCleanup ? 0.4 : 0), execute: workItem)
    }

    private func startAdLoad(_ adRequest: AdRequest) {
        do {
            let adgeist = AdgeistCore.getInstance()
            let fetchCreative = adgeist.getCreative()
            isTestMode = adRequest.isTestMode
            fetchCreative.fetchCreative(
                adUnitID: adUnitId,
                buyType: "FIXED",
                isTestEnvironment: isTestMode
            ) { [weak self] adData in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isLoading = false
                    if self.isDestroyed { return }
                    if !adData.isSuccess {
                        print("\(Self.TAG): API error: \(adData.errorMessage), statusCode: \(adData.statusCode?.description ?? "nil")")
                        self.listener?.onAdFailedToLoad(adData.errorMessage)
                        return
                    }
                    self.handleAdResponse(adData.data)
                }
            }
        } catch {
            print("\(Self.TAG): startAdLoad exception: \(error.localizedDescription)")
            listener?.onAdFailedToLoad(error.localizedDescription)
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
            }
        }
    }

    private func handleAdResponse(_ response: Any?) {
        guard let fixed = response as? FixedAdResponse else {
            print("\(Self.TAG): API error: No creative returned")
            listener?.onAdFailedToLoad("No creative returned")
            return
        }
        if fixed.creativesV1.isEmpty {
            print("\(Self.TAG): Empty creative list")
            listener?.onAdFailedToLoad("Empty creative")
            return
        }

        metaData = fixed.metaData

        var propertiesForAdCard: [String: Any?] = [:]
        propertiesForAdCard["adspaceType"] = adType.rawValue
        propertiesForAdCard["adElementId"] = "adgeist_ads_iframe_\(adUnitId)"
        propertiesForAdCard["name"] = fixed.advertiser?.name ?? "-"

        let options = fixed.displayOptions
        propertiesForAdCard["isResponsive"] = options?.isResponsive ?? false
        propertiesForAdCard["responsiveType"] = options?.responsiveType ?? "Square"

        let creativeDataFromApiResponse = fixed.creativesV1[0]
        propertiesForAdCard["title"] = creativeDataFromApiResponse.title
        propertiesForAdCard["description"] = creativeDataFromApiResponse.description
        propertiesForAdCard["ctaUrl"] = creativeDataFromApiResponse.ctaUrl

        if adIsResponsive {
            propertiesForAdCard["width"] = Int(bounds.width)
            propertiesForAdCard["height"] = Int(bounds.height)
        } else {
            propertiesForAdCard["width"] = adSize?.width ?? 300
            propertiesForAdCard["height"] = adSize?.height ?? 300
        }

        // Add primaryCreative
        var primaryCreative: [String: String?] = [:]
        primaryCreative["src"] = creativeDataFromApiResponse.primary?.fileUrl
        primaryCreative["thumbnailUrl"] = creativeDataFromApiResponse.primary?.thumbnailUrl
        primaryCreative["type"] = creativeDataFromApiResponse.primary?.type

        // Add companionCreative
        let companionCreative = creativeDataFromApiResponse.companions?.map { companion in
            return [
                "src": companion.fileUrl,
                "thumbnailUrl": companion.thumbnailUrl,
                "type": companion.type
            ]
        } ?? []

        var mediaList: [[String: String?]] = []
        mediaList.append(primaryCreative)
        mediaList.append(contentsOf: companionCreative)
        propertiesForAdCard["media"] = mediaList

        let jsonString = dictToJson(propertiesForAdCard)
        renderAdWithAdCard(creativeJsonData: jsonString)
        notifyAdLoaded()
    }

    /// Creates and configures a new WebView, sets up the JavaScript bridge,
    /// and registers the resulting session so this ad survives view/window churn.
    private func renderAdWithAdCard(creativeJsonData: String) {
        if isDestroyed { return }

        // Remove all subviews
        subviews.forEach { $0.removeFromSuperview() }

        // Setup WebView configuration
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        if #available(iOS 14.0, *) {
            let preferences = WKWebpagePreferences()
            preferences.allowsContentJavaScript = true
            config.defaultWebpagePreferences = preferences
        } else {
            config.preferences.javaScriptEnabled = true
        }

        jsInterface = JsBridge(baseAdView: self)
        config.userContentController.add(jsInterface!, name: "postMessage")
        config.userContentController.add(jsInterface!, name: "postVideoStatus")
        config.userContentController.add(jsInterface!, name: "reportOverflow")
        config.userContentController.add(jsInterface!, name: "showAd")

        config.userContentController.add(self, name: "iosConsole")

        // Enable WebView debugging
        injectConsoleLoggingScript()

        // Create WebView
        webView = WKWebView(frame: .zero, configuration: config)

        webView?.isInspectable = true
        webView?.scrollView.isScrollEnabled = false
        webView?.translatesAutoresizingMaskIntoConstraints = false
        webView?.navigationDelegate = self
        webView?.uiDelegate = self
        webView?.isOpaque = false
        webView?.backgroundColor = .clear
        webView?.scrollView.backgroundColor = .clear

        // Add WebView to view hierarchy
        if let webView = webView {
            addSubview(webView)
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: topAnchor),
                webView.leadingAnchor.constraint(equalTo: leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: trailingAnchor),
                webView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }

        listener?.onAdOpened()

        let html = buildAdCardHtml(creativeJsonData: creativeJsonData)
        webView?.loadHTMLString(html, baseURL: URL(string: "https://adgeist.ai")!)

        // Hide companion ads initially until overflow check completes
        if adType == .COMPANION {
            webView?.isHidden = true
        }

        // Register the session so this ad survives view/window churn; a view
        // without a resolvable placement identity gets no retention.
        if let webView = webView, let jsInterface = jsInterface, let key = sessionKey() {
            activeSessionKey = key
            AdSessionStore.put(
                key: key,
                session: AdSession(
                    webView: webView,
                    jsInterface: jsInterface,
                    metaData: metaData,
                    mediaType: mediaType,
                    isTestMode: isTestMode,
                    hostView: self
                )
            )
            print("\(Self.TAG): Registered ad session '\(key)'")
        }
        registerHostDestroyWatcher()
    }

    private func injectConsoleLoggingScript() {
        let scriptSource = """
        (function() {
            const origLog = console.log;
            const origError = console.error;
            const origWarn = console.warn;

            function send(level, args) {
                const msg = args.map(a => String(a ?? 'undefined')).join(' ');
                window.webkit.messageHandlers.iosConsole.postMessage({
                    level: level,
                    message: msg
                });
            }

            console.log = (...args) => { send('LOG', args); origLog.apply(console, args); };
            console.error = (...args) => { send('ERROR', args); origError.apply(console, args); };
            console.warn = (...args) => { send('WARN', args); origWarn.apply(console, args); };
        })();
        """

        let script = WKUserScript(
            source: scriptSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        webView?.configuration.userContentController.addUserScript(script)
        webView?.configuration.userContentController.add(self, name: "iosConsole")
    }

    private func buildAdCardHtml(creativeJsonData: String) -> String {
        let escapedJson = creativeJsonData
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
            .replacingOccurrences(of: "`", with: "\\`")
        guard let path = Bundle(for: type(of: self)).path(forResource: "ad_view", ofType: "html"),
              let template = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("\(Self.TAG): Failed to load ad_view.html from assets")
            return ""
        }
        guard let adCardJsPath = Bundle(for: type(of: self)).path(forResource: "adcard-beta", ofType: "js"),
              let adCardJs = try? String(contentsOfFile: adCardJsPath, encoding: .utf8) else {
            print("\(Self.TAG): Failed to load adcard-beta.js from assets")
            return ""
        }
        return template
            .replacingOccurrences(of: "{{ADCARD_JS}}", with: adCardJs)
            .replacingOccurrences(of: "{{CREATIVE_DATA}}", with: escapedJson)
    }

    private func dictToJson(_ dict: [String: Any?]) -> String {
        let cleaned = dict.compactMapValues { $0 }
        guard JSONSerialization.isValidJSONObject(cleaned) else {
            print("\(Self.TAG): Invalid JSON object – contains unsupported types")
            return "{}"
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: cleaned, options: [])
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            print("\(Self.TAG): JSON serialization failed: \(error)")
            return "{}"
        }
    }

    private func notifyAdLoaded() {
        listener?.onAdLoaded()
    }

    // MARK: - Ad session management

    /// Takes over a surviving session: re-parents its rendered WebView into
    /// this view and rebinds tracking. Impression state carries over, so
    /// analytics are not double-fired.
    private func adoptSession(key: String, session: AdSession) {
        print("\(Self.TAG): Adopting live ad session '\(key)' - same ad, no re-fetch")

        if let previousHost = session.hostView, previousHost !== self {
            previousHost.releaseSession()
        }
        session.hostView = self
        activeSessionKey = key

        isDestroyed = false
        isLoading = false
        metaData = session.metaData
        mediaType = session.mediaType
        isTestMode = session.isTestMode
        webView = session.webView
        jsInterface = session.jsInterface

        // Detach the WebView from wherever it was previously hosted, explicitly
        // deactivating any cross-hierarchy Auto Layout constraints before the
        // move rather than relying solely on removeFromSuperview()'s implicit
        // behavior for something this correctness-critical.
        if let oldSuperview = session.webView.superview, oldSuperview !== self {
            let crossConstraints = oldSuperview.constraints.filter {
                ($0.firstItem as? UIView) === session.webView || ($0.secondItem as? UIView) === session.webView
            }
            NSLayoutConstraint.deactivate(crossConstraints)
            session.webView.removeFromSuperview()
        }
        subviews.forEach { $0.removeFromSuperview() }
        addSubview(session.webView)
        NSLayoutConstraint.activate([
            session.webView.topAnchor.constraint(equalTo: topAnchor),
            session.webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            session.webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            session.webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        jsInterface?.rebind(to: self)
        registerHostDestroyWatcher()

        // No network fetch happened, but the publisher callback still fires.
        listener?.onAdLoaded()
    }

    /// Detaches this view from its session WITHOUT destroying the shared
    /// WebView, when another BaseAdView adopts it. destroy() then no-ops here.
    private func releaseSession() {
        unregisterHostDestroyWatcher()
        pendingLoadWorkItem?.cancel()
        pendingLoadWorkItem = nil
        webView = nil
        jsInterface = nil
        activeSessionKey = nil
        isDestroyed = true
        isLoading = false
    }

    // Placement identity, best effort: explicit placementId, else the view's
    // accessibility identifier, else the hosting view controller's type, else
    // none (no retention). Integrators who want reliable session retention
    // should set placementId explicitly.
    private func resolvePlacementKey() -> String {
        if !placementId.isEmpty { return placementId }
        if let identifier = accessibilityIdentifier, !identifier.isEmpty {
            return "vid:\(identifier)"
        }
        if let hostVC = findHostViewController() {
            return "vc:\(type(of: hostVC))"
        }
        return ""
    }

    private func sessionKey() -> String? {
        let placement = resolvePlacementKey()
        guard !placement.isEmpty else { return nil }
        return "\(adUnitId)|\(placement)"
    }

    // MARK: - Measurement and layout

    /// Centers the WebView child within this container.
    public override func layoutSubviews() {
        super.layoutSubviews()

        guard let child = subviews.first, child.isHidden == false else { return }

        let width = child.frame.width
        let height = child.frame.height

        let horizontalSpacing = (bounds.width - width) / 2
        let verticalSpacing = (bounds.height - height) / 2

        child.frame = CGRect(
            x: horizontalSpacing,
            y: verticalSpacing,
            width: width,
            height: height
        )
    }

    /// Measures the ad view based on ad size or child view, handling
    /// responsive sizing and fixed ad sizes.
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let child = subviews.first, child.isHidden == false else {
            if adIsResponsive {
                return size
            } else if let adSize = adSize {
                return CGSize(width: adSize.getWidthInPixels(), height: adSize.getHeightInPixels())
            }
            return .zero
        }

        let childSize = child.sizeThatFits(size)
        let width = max(childSize.width, suggestedMinimumWidth)
        let height = max(childSize.height, suggestedMinimumHeight)

        return CGSize(width: width, height: height)
    }

    private var suggestedMinimumWidth: CGFloat {
        return 0
    }

    private var suggestedMinimumHeight: CGFloat {
        return 0
    }

    // MARK: - Window lifecycle

    /// Equivalent to Android's onDetachedFromWindow. Window detach is often
    /// transient (a covering push, not a real teardown), so this only pauses
    /// tracking - it no longer destroys the WebView.
    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil, !isDestroyed {
            jsInterface?.onHostDetached()
        }
    }

    /// Equivalent to Android's onAttachedToWindow.
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        registerHostDestroyWatcher()
        guard !isDestroyed else { return }
        jsInterface?.onHostAttached()
    }

    // MARK: - Host destroy watcher

    /// Deinit-fires-a-closure canary attached to the hosting UIViewController via
    /// the ObjC associated-object mechanism. Its deinit fires exactly when the
    /// host VC deallocates (genuinely popped/discarded with no other retainers),
    /// as opposed to merely being window-detached while covered - the closest
    /// iOS analog to Android's Fragment-instance Lifecycle.onDestroy. Multiple
    /// ad slots on one screen each get their own canary, stored in an array on
    /// the host VC, so they can't clobber each other via associated-object keys.
    private final class HostDestroyCanary {
        private let onDeinit: () -> Void
        init(onDeinit: @escaping () -> Void) { self.onDeinit = onDeinit }
        deinit { onDeinit() }
    }

    private func findHostViewController() -> UIViewController? {
        var responder: UIResponder? = self.next
        while let r = responder {
            if let vc = r as? UIViewController { return vc }
            responder = r.next
        }
        return nil
    }

    private func registerHostDestroyWatcher() {
        guard hostDestroyCanary == nil, let hostVC = findHostViewController() else { return }

        let canary = HostDestroyCanary { [weak self] in
            // deinit has no thread guarantee; destroy() touches UIKit/WKWebView.
            DispatchQueue.main.async { self?.destroy() }
        }
        var canaries = objc_getAssociatedObject(hostVC, &Self.canariesAssociationKey) as? [HostDestroyCanary] ?? []
        canaries.append(canary)
        objc_setAssociatedObject(hostVC, &Self.canariesAssociationKey, canaries, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        hostDestroyCanary = canary
        registeredHostVC = hostVC
    }

    private func unregisterHostDestroyWatcher() {
        defer {
            hostDestroyCanary = nil
            registeredHostVC = nil
        }
        guard let canary = hostDestroyCanary, let hostVC = registeredHostVC else { return }
        var canaries = objc_getAssociatedObject(hostVC, &Self.canariesAssociationKey) as? [HostDestroyCanary] ?? []
        canaries.removeAll { $0 === canary }
        objc_setAssociatedObject(hostVC, &Self.canariesAssociationKey, canaries, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    // MARK: - Teardown

    /// Destroys the ad view and releases all resources.
    public func destroy() {
        guard !isDestroyed else { return }
        isLoading = false
        unregisterHostDestroyWatcher()
        pendingLoadWorkItem?.cancel()
        pendingLoadWorkItem = nil
        listener?.onAdClosed()
        safelyDestroyWebView()
    }

    /// Safely destroys the WebView to prevent memory leaks. Performs cleanup
    /// in order: removes the JS interface, stops loading, clears scripts,
    /// removes from the view hierarchy, loads a blank page, then destroys
    /// the WebView instance.
    private func safelyDestroyWebView() {
        guard !isDestroyed else { return }
        isDestroyed = true
        let webViewToDestroy = webView
        webView = nil
        jsInterface?.destroyListeners()
        jsInterface = nil

        if let key = activeSessionKey, let webViewToDestroy = webViewToDestroy {
            AdSessionStore.removeIfHosts(key: key, webView: webViewToDestroy)
        }
        activeSessionKey = nil

        guard let webView = webViewToDestroy else { return }
        DispatchQueue.main.async {
            // Remove JS interface
            webView.configuration.userContentController.removeAllScriptMessageHandlers()
            webView.stopLoading()
            webView.configuration.userContentController.removeAllUserScripts()
            // Remove from superview
            if let parent = webView.superview {
                parent.subviews.forEach { $0.removeFromSuperview() }
            }
            // Load blank
            if let blank = URL(string: "about:blank") {
                webView.load(URLRequest(url: blank))
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                // Final cleanup
                webView.navigationDelegate = nil
                webView.uiDelegate = nil
                print("\(Self.TAG): WebView destroyed safely")
            }
        }
    }

    // MARK: - Helpers

    private func dpToPx(_ dp: Int) -> Int {
        return Int(CGFloat(dp) * UIScreen.main.scale)
    }

    private func pxToDp(_ px: Int) -> Int {
        return Int(CGFloat(px) / UIScreen.main.scale)
    }

    private func openInBrowser(url: String) {
        guard let urlObj = URL(string: url) else {
            print("\(Self.TAG): Invalid URL: \(url)")
            return
        }

        if UIApplication.shared.canOpenURL(urlObj) {
            UIApplication.shared.open(urlObj, options: [:]) { success in
                if !success {
                    print("\(Self.TAG): Failed to open external URL: \(url)")
                }
            }
        }
    }

    deinit {
        destroy()
    }
}

/**
 * Extension to handle console messages from WebView JavaScript.
 * Captures and logs JavaScript console output for debugging.
 */
extension BaseAdView: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "iosConsole",
           let body = message.body as? [String: Any],
           let level = body["level"] as? String,
           let msg = body["message"] as? String {
            switch level {
            case "ERROR":
                print("\(Self.TAG): 🔴 JS Error: \(msg)")
                listener?.onAdFailedToLoad("JS Error: \(msg)")
            case "WARN":
                print("\(Self.TAG): 🟡 JS Warning: \(msg)")
            default:
                break
            }
        }
    }
}

/**
 * Extension to handle WebView navigation events.
 * Intercepts link clicks and manages page loading.
 */
extension BaseAdView: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url {
            openInBrowser(url: url.absoluteString)
            jsInterface?.recordClickListener()
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("\(Self.TAG): ✅ WebView page finished loading")
    }
}

/**
 * Extension to handle WebView UI delegate methods.
 */
extension BaseAdView: WKUIDelegate {}
