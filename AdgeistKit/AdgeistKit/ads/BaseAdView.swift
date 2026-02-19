import UIKit
import WebKit

open class BaseAdView: UIView {

    private static let TAG = "BaseAdView"

    /**
     * Required parameters for ad rendering configuration
     */
    public var adSize: AdSize? = nil
    public var adUnitId: String = ""
    public var adType: String = "banner"
    public var adIsResponsive: Bool = false
    public var isTestMode: Bool = false

    /**
     * Metadata and media type for ad tracking
     */
    public var metaData: String = ""
    public var mediaType: String? = nil
    
    /**
     * WebView and JavaScript bridge instances
     */
    internal var webView: WKWebView?
    private var jsInterface: JsBridge?
    private var adActivity: AdActivity?
    
    /**
     * Listener for ad lifecycle events
     */
    public var listener: AdListener?
    
    private var isLoading: Bool = false
    private var isDestroyed = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    /**
     * Initializes the BaseAdView.
     * In iOS, initialization is handled by init methods.
     */
    private func initialize() {
    }

    /**
     * Converts density-independent pixels (dp) to actual pixels.
     *
     * @param dp Value in density-independent pixels
     * @return Value in pixels based on device density
     */
    private func dpToPx(_ dp: Int) -> Int {
        return Int(CGFloat(dp) * UIScreen.main.scale)
    }
    
    /**
     * Converts pixels to density-independent pixels (dp).
     *
     * @param px Value in pixels
     * @return Value in density-independent pixels
     */
    private func pxToDp(_ px: Int) -> Int {
        return Int(CGFloat(px) / UIScreen.main.scale)
    }

    /**
     * Sets the ad listener to receive ad lifecycle events.
     *
     * @param listener AdListener implementation or nil to remove listener
     */
    public func setAdListener(_ listener: AdListener?) {
        self.listener = listener
    }

    /**
     * Loads an ad with the specified AdRequest.
     * This is the main entry point for publishers to request and display ads.
     * Note: If an ad is already loading, this call will be ignored.
     *
     * @param adRequest The AdRequest containing ad configuration (test mode, etc.)
     */
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
        // Reset destroyed flag to allow reloading
        isDestroyed = false
        isLoading = true
        // Destroy any existing WebView before loading new ad
        if webView != nil {
            safelyDestroyWebView()
        }
        // Wait a bit before loading new ad to ensure cleanup completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self, !self.isDestroyed else { return }
            self.startAdLoad(adRequest)
        }
    }
    
    /**
     * Initiates the actual ad loading process by fetching creative from the server.
     *
     * @param adRequest The AdRequest containing configuration parameters
     */
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
                    if self.isDestroyed { return }
                    self.isLoading = false
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
        propertiesForAdCard["adspaceType"] = adType
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
            propertiesForAdCard["width"] = pxToDp(Int(bounds.width))
            propertiesForAdCard["height"] = pxToDp(Int(bounds.height))
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

    /**
     * Creates and configures a new WebView, sets up JavaScript bridge.
     *
     * @param creativeJsonData JSON string containing creative data for rendering
     */
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
                
        adActivity = jsInterface?.adActivity
        listener?.onAdOpened()

        let html = buildAdCardHtml(creativeJsonData: creativeJsonData)
        webView?.loadHTMLString(html, baseURL: URL(string: "https://adgeist.ai")!)
        
        // Hide companion ads initially until overflow check completes
        if adType == "companion" {
            webView?.isHidden = true
        }
    }
    
    /**
     * Injects JavaScript to capture console messages from WebView.
     * Redirects console.log, console.error, and console.warn to native code.
     */
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
    
    /**
     * Builds the HTML content for ad rendering in WebView.
     * Loads the main ad view file from assets and injects creative data.
     * This file loads the AdCard library from S3 and renders the ad.
     *
     * @param creativeJsonData JSON string with creative data
     * @return Complete HTML string ready to be loaded in WebView
     */
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
        return template.replacingOccurrences(of: "{{CREATIVE_DATA}}", with: escapedJson)
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

    /**
     * Positions the child view (WebView) within the ad container.
     * Centers the ad content both horizontally and vertically.
     */
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

    /**
     * Measures the dimensions of the ad view based on ad size or child view.
     * Handles responsive sizing and fixed ad sizes.
     */
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
    
    /**
     * Opens a URL in the device's default browser.
     *
     * @param url URL to open in browser
     */
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
    
    /**
     * Called when the view is attached to a window.
     * Equivalent to Android's onAttachedToWindow.
     */
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if window != nil {
            // Attached to window - WebView resumes automatically in iOS
            if webView != nil && !isDestroyed {
                // WebView is now visible
            }
        }
    }
    
    /**
     * Called when the view is detached from a window.
     * Equivalent to Android's onDetachedFromWindow.
     * Triggers WebView cleanup and notifies listener.
     */
    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        if newWindow == nil {
            onDestroyWebView()
        }
    }
    
    /**
     * Sets the ad dimensions for fixed-size ads.
     *
     * @param adSize The desired ad size
     */
    public func setAdDimension(_ adSize: AdSize) {
        self.adSize = adSize
        setNeedsLayout()
    }
    
    public var isCollapsible: Bool {
        return false
    }

    /**
     * Destroys the ad view and releases all resources.
     */
    public func destroy() {
        isLoading = false
        safelyDestroyWebView()
    }
    
    /**
     * Safely destroys the WebView to prevent memory leaks.
     * Performs cleanup in the correct order:
     * 1. Removes JavaScript interface
     * 2. Stops loading
     * 3. Clears scripts and cache
     * 4. Removes from view hierarchy
     * 5. Loads blank page
     * 6. Destroys WebView instance
     */
    private func safelyDestroyWebView() {
        guard !isDestroyed else { return }
        isDestroyed = true
        let webViewToDestroy = webView
        webView = nil
        jsInterface?.destroyListeners()
        jsInterface = nil
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
    
    /**
     * Internal method called when WebView is being destroyed.
     */
    private func onDestroyWebView() {
        listener?.onAdClosed()
        safelyDestroyWebView()
    }
    
    private func notifyAdLoaded() {
        listener?.onAdLoaded()
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
