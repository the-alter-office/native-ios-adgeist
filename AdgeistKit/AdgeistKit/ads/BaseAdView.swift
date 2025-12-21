import UIKit
import WebKit

open class BaseAdView: UIView {

    private static let TAG = "BaseAdView"

    public var adSize: AdSize? = nil
    public var adUnitId: String = ""
    public var adType: String = "banner"
    
    public var mediaType: String? = nil
    public var isTestMode: Bool = false
    public var metaData: String = ""
    
    // WebView and JS Bridge
    public var webView: WKWebView?
    private var jsInterface: JsBridge?
    private var adActivity: AdActivity?
    
    // Listener
    public var listener: AdListener?
    
    // Internal state
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
    
    private func initialize() {
    }

    private func dpToPx(_ dp: Int) -> Int {
        return Int(CGFloat(dp) * UIScreen.main.scale)
    }
    
    private func pxToDp(_ px: Int) -> Int {
        return Int(CGFloat(px) / UIScreen.main.scale)
    }

    public func setAdListener(_ listener: AdListener?) {
        self.listener = listener
    }

    public func loadAd(_ adRequest: AdRequest) {
        if isLoading {
            print("\(Self.TAG): Ad is already loading")
            return
        }
        
        if adUnitId.isEmpty {
            print("\(Self.TAG): Ad unit ID is null or empty")
            return
        }
        
        // Reset destroyed flag to allow reloading
        isDestroyed = false
        isLoading = true
        
        // Destroy any existing WebView before loading new ad
        if webView != nil {
            print("\(Self.TAG): Destroying webview from loadAd method")
            safelyDestroyWebView()
        }
        
        // Wait a bit before loading new ad to ensure cleanup completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self, !self.isDestroyed else { return }
            self.startAdLoad(adRequest)
        }
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
            ) { [weak self] response in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    if self.isDestroyed { return }
                    self.isLoading = false
                    
                    self.handleAdResponse(response)
                }
            }
        } catch {
            listener?.onAdFailedToLoad(error.localizedDescription)
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                print("\(Self.TAG): Error loading ad: \(error)")
            }
        }
    }

    private func handleAdResponse(_ response: Any?) {
        guard let fixed = response as? FixedAdResponse,
              let creative = fixed.creatives?.first else {
            listener?.onAdFailedToLoad("No creative returned")
            return
        }
        
        if fixed.creatives?.isEmpty ?? true {
            listener?.onAdFailedToLoad("Empty creative")
            return
        }

        mediaType = creative.type   
        metaData = fixed.metaData

        let simpleCreative: [String: Any?] = [
            "adElementId": "adgeist_ads_iframe_\(adUnitId)",
            "title": creative.title,
            "description": creative.description,
            "name": fixed.advertiser?.name ?? "-",
            "ctaUrl": creative.ctaUrl,
            "fileUrl": creative.fileUrl,
            "type": creative.type,
            "isResponsive": fixed.displayOptions?.isResponsive ?? false,
            "responsiveType": fixed.displayOptions?.responsiveType ?? "Square",
            "width": adSize?.width ?? 300,
            "height": adSize?.height ?? 300,
            "adspaceType": adType,
            "media": creative.fileUrl != nil ? [["src": creative.fileUrl!]] : [],
            "mediaType": creative.type ?? "image"
        ]

        let jsonString = dictToJson(simpleCreative)
        renderAdWithAdCard(creativeJsonData: jsonString)
        notifyAdLoaded()
    }

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

        let escaped = creativeJsonData
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")

        let html = buildAdCardHtml(escapedJson: escaped)
        webView?.loadHTMLString(html, baseURL: URL(string: "https://adgeist.ai")!)
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
    
    private func buildAdCardHtml(escapedJson: String) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                html, body {
                    width: 100%;
                    height: 100%;
                    margin: 0;
                    padding: 0;
                    overflow: hidden;
                }
                body {
                    display: flex;
                    justify-content: center;
                    align-items: center;
                }
                #ad-content {
                    width: 100%;
                    height: 100%;
                }
                #ad-content > * {
                    width: 100%;
                    height: 100%;
                    object-fit: inherit;
                }
            </style>
        </head>
        <body>
            <div id='ad-content'></div>
            <!-- Load AdCard.js library from S3 -->
            <script src='https://cdn.adgeist.ai/adcard-beta.js'></script>
            <script>
                function initAd() {
                    if (typeof AdCard === 'undefined') {
                        console.error('AdCard library not loaded');
                        return;
                    }
                    try {
                        const creativeData = JSON.parse("\(escapedJson)");
                        const adCard = new AdCard(creativeData);
                        const html = adCard.renderHtml();
                        document.getElementById('ad-content').innerHTML = html;
                        document.getElementById('ad-content').addEventListener('click', function(e) {
                            console.log('Ad clicked');
                        });
                    } catch (error) {
                        console.error('Error rendering ad:', error);
                    }
                }
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', function() {
                        setTimeout(initAd, 100);
                    });
                } else {
                    setTimeout(initAd, 100);
                }
            </script>
        </body>
        </html>
        """
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

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let child = subviews.first, child.isHidden == false else {
            if let adSize = adSize {
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
    
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if window != nil {
            // Attached to window
            if let webView = webView, !isDestroyed {
                // Resume WebView if needed
            }
        }
    }
    
    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        if newWindow == nil {
            print("\(Self.TAG) Destroying Webview from willMove Method")
            onDestroyWebView()
        }
    }
    
    public func setAdDimension(_ adSize: AdSize) {
        self.adSize = adSize
        setNeedsLayout()
    }
    
    public var isCollapsible: Bool {
        return false
    }

    public func destroy() {
        print("\(Self.TAG) destroy method triggered")
        isLoading = false
        safelyDestroyWebView()
    }
    
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
    
    private func onDestroyWebView() {
        listener?.onAdClosed()
        safelyDestroyWebView()
    }
    
    private func notifyAdLoaded() {
        listener?.onAdLoaded()
    }
    
    deinit {
        print("\(Self.TAG): Destroying webview from deinit method")
        destroy()
    }
}

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
                print("\(Self.TAG): 🔵 JS Log: \(msg)")
            }
        }
    }
}

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

extension BaseAdView: WKUIDelegate {}
