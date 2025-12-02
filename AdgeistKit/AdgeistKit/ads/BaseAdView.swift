import UIKit
import WebKit

open class BaseAdView: UIView {

    private static let TAG = "BaseAdView"

    // Public configurable properties
    public var adUnitId: String = ""
    public var adSize: AdSize?
    public var adType: String = "banner"
    public var customOrigin: String?
    public var appID: String?

    // Internal state
    public var listener: AdListener?
    public var metaData: String = ""
    public var isTestMode = false
    public var mediaType: String?

    private var isDestroyed = false
    
    // WebView & bridges
    open var webView: WKWebView!
    private var jsBridge: JsBridge?
    private var adActivity: AdActivity?


    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupWebView()
    }
    
   
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWebView()
    }

    // MARK: - WebView Setup (Modern + Debuggable)
    private func setupWebView() {
        let config = WKWebViewConfiguration()

        // Media playback
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // JavaScript Enabled (Modern way – no deprecation)
        if #available(iOS 14.0, *) {
            let preferences = WKWebpagePreferences()
            preferences.allowsContentJavaScript = true
            config.defaultWebpagePreferences = preferences
        } else {
            config.preferences.javaScriptEnabled = true
        }

        // Create the WebView FIRST (with config)
        webView = WKWebView(frame: .zero, configuration: config)
        
        // NOW set isInspectable on the WebView instance
        if #available(iOS 16.4, *) {
            webView.isInspectable = true 
        }

        webView.scrollView.isScrollEnabled = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self

        addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Inject console logging
        injectConsoleLoggingScript()
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
        webView.configuration.userContentController.addUserScript(script)
        webView.configuration.userContentController.add(self, name: "iosConsole")
    }

    // MARK: - Public API
    public func setAdListener(_ listener: AdListener) {
        self.listener = listener
    }

    public func setAdDimension(_ adSize: AdSize) {
        guard self.adSize != adSize else { return }
            
        self.adSize = adSize
        invalidateIntrinsicContentSize()
    }

    public func loadAd(_ adRequest: AdRequest) {
        guard let appID = appID ?? getMetaDataValue("Adgeist_APP_ID"),
              let origin = customOrigin ?? getMetaDataValue("Adgeist_ORIGIN") else {
            listener?.onAdFailedToLoad("Missing APP_ID or ORIGIN in Info.plist")
            return
        }
        
        isTestMode = adRequest.isTestMode

        AdgeistCore.getInstance().getCreative().fetchCreative(
            apiKey: getMetaDataValue("Adgeist_API_KEY") ?? "",
            origin: origin,
            adSpaceId: adUnitId,
            companyId: appID,
            buyType: "FIXED",
            isTestEnvironment: isTestMode
        ) { [weak self] response in
            DispatchQueue.main.async {
                self?.handleAdResponse(response)
            }
        }
    }

    // MARK: - Handle Response & Render
    private func handleAdResponse(_ response: Any?) {
        guard let fixed = response as? FixedAdResponse,
              let creative = fixed.creatives?.first else {
            listener?.onAdFailedToLoad("No creative received")
            return
        }

        mediaType = creative.type   
        metaData = fixed.metaData

        let simpleCreative: [String: Any?] = [
            "adElementId": "adgeist_ads_iframe_\(adUnitId)",
            "title": creative.title,
            "description": creative.description,
            "name": fixed.advertiser?.name ?? "Advertiser",
            "ctaUrl": creative.ctaUrl,
            "fileUrl": creative.fileUrl,
            "type": creative.type,
            "isResponsive": fixed.displayOptions?.isResponsive ?? false,
            "responsiveType": fixed.displayOptions?.responsiveType ?? "Square",
            "width": fixed.displayOptions?.dimensions?.width ?? 300,
            "height": fixed.displayOptions?.dimensions?.height ?? 300,
            "adspaceType": adType,
            "media": creative.fileUrl != nil ? [["src": creative.fileUrl!]] : [],
            "mediaType": creative.type ?? "image"
        ]

        let jsonString = dictToJson(simpleCreative)
        renderAdWithAdCard(creativeJsonData: jsonString)
        listener?.onAdLoaded()
    }

    private func renderAdWithAdCard(creativeJsonData: String) {
        // Clean previous content
        webView.configuration.userContentController.removeAllUserScripts()
        webView.configuration.userContentController.removeAllScriptMessageHandlers()

        // Re-inject console logger + JS bridge
        injectConsoleLoggingScript()

        jsBridge = JsBridge(baseAdView: self)
        webView.configuration.userContentController.add(jsBridge!, name: "postMessage")
        webView.configuration.userContentController.add(jsBridge!, name: "postVideoStatus")

        adActivity = jsBridge?.adActivity
        listener?.onAdOpened()

        let escaped = creativeJsonData
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin:0; padding:0; box-sizing:border-box; }
                html,body { width:100%; height:100%; overflow:hidden; }
                body { display:flex; justify-content:center; align-items:center; background:transparent; }
                #ad-content { width:100%; height:100%; }
                #ad-content > * { width:100%; height:100%; object-fit:contain; }
            </style>
        </head>
        <body>
            <div id="ad-content"></div>
            <script src="https://cdn.adgeist.ai/adcard-beta.js"></script>
            <script>
                function initAd() {
                    if (typeof AdCard === 'undefined') {
                        console.error('AdCard library not loaded');
                        return;
                    }
                    try {
                        const creativeData = JSON.parse("\(escaped)");
                        const adCard = new AdCard(creativeData);
                        window.adCardInstance = adCard;
                        document.getElementById('ad-content').innerHTML = adCard.renderHtml();

                        document.getElementById('ad-content').addEventListener('click', () => {
                            console.log('Ad clicked');
                            window.webkit.messageHandlers.postMessage.postMessage({
                                type: 'click',
                                url: creativeData.ctaUrl || ''
                            });
                        });

                        window.webkit.messageHandlers.postMessage.postMessage({ type: 'impression' });
                    } catch (e) {
                        console.error('AdCard render failed:', e);
                    }
                }
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', () => setTimeout(initAd, 100));
                } else {
                    setTimeout(initAd, 100);
                }
            </script>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: URL(string: "https://adgeist.ai")!)

        // Capture impression after render
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.adActivity?.captureImpression()
        }
    }

    // MARK: - Helpers
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

    private func getMetaDataValue(_ key: String) -> String? {
        return Bundle.main.object(forInfoDictionaryKey: key) as? String
    }

    public func destroy() {
        guard !isDestroyed else { return }
            isDestroyed = true

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                // Break delegate cycles
                self.webView?.navigationDelegate = nil
                self.webView?.uiDelegate = nil
                self.webView?.scrollView.delegate = nil

                // Clean WebView
                self.webView?.stopLoading()
                self.webView?.configuration.userContentController.removeAllUserScripts()
                self.webView?.configuration.userContentController.removeAllScriptMessageHandlers()

                // Clean up bridges
                self.adActivity?.destroy()
                self.jsBridge?.destroyListeners()

                // Remove from view hierarchy
                self.webView?.removeFromSuperview()

                // Optional: clear content
                if let blank = URL(string: "about:blank") {
                    self.webView?.load(URLRequest(url: blank))
                }
            }    }

    deinit {
        destroy()
    }
}

// MARK: - WKScriptMessageHandler: Console Logs
extension BaseAdView: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "iosConsole",
           let body = message.body as? [String: Any],
           let level = body["level"] as? String,
           let msg = body["message"] as? String {

            switch level {
            case "ERROR":
                print("JS Error: \(msg)")
                listener?.onAdFailedToLoad("JS Error: \(msg)")
            case "WARN":
                print("JS Warn: \(msg)")
            default:
                print("JS Log: \(msg)")
            }
        }
    }
}

// MARK: - WKNavigationDelegate: Click Handling
extension BaseAdView: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url {
            jsBridge?.recordClickListener()
            UIApplication.shared.open(url)
            listener?.onAdClicked()
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}

extension BaseAdView: WKUIDelegate {}
