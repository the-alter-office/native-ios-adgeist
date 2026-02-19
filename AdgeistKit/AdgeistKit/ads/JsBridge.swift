import Foundation
import WebKit

class JsBridge: NSObject, WKScriptMessageHandler {
    private static let TAG = "Javascript Bridge"
    
    private weak var baseAdView: BaseAdView?
    public var adActivity: AdActivity?
    
    init(baseAdView: BaseAdView) {
        self.baseAdView = baseAdView
        super.init()
        initializeAdTracker()
    }
    
    private func initializeAdTracker() {
        guard let baseAdView = baseAdView else { return }
        adActivity = AdActivity(baseAdView: baseAdView)
    }
    
    func recordClickListener() {
        adActivity?.captureClick()
    }
    
    func destroyListeners() {
        adActivity?.destroy()
        adActivity = nil
    }
    
    // WKScriptMessageHandler protocol method
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "postMessage" {
            guard let bodyString = message.body as? String else { return }
            postMessage(json: bodyString)
        } else if message.name == "postVideoStatus" {
            guard let bodyString = message.body as? String else { return }
            postVideoStatus(json: bodyString)
        } else if message.name == "reportOverflow" {
            guard let body = message.body as? [String: Any],
                  let contentWidth = body["contentWidth"] as? Int,
                  let contentHeight = body["contentHeight"] as? Int,
                  let viewWidth = body["viewWidth"] as? Int,
                  let viewHeight = body["viewHeight"] as? Int else { return }
            reportOverflow(contentWidth: contentWidth, contentHeight: contentHeight, viewWidth: viewWidth, viewHeight: viewHeight)
        } else if message.name == "showAd" {
            showAd()
        }
    }
    
    private func postMessage(json: String) {
        guard let data = json.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("\(Self.TAG): Invalid JSON: \(json)")
            return
        }
        let type = jsonObject["type"] as? String ?? ""
        let msg = jsonObject["message"] as? String ?? ""
        if type == "RENDER_STATUS" && msg == "Success" {
            adActivity?.captureImpression()
        }
    }
    
    private func postVideoStatus(json: String) {
        guard let data = json.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("\(Self.TAG): Invalid JSON in postVideoStatus: \(json)")
            return
        }
        let type = jsonObject["type"] as? String ?? ""
        if type == "PLAY" {
            adActivity?.onVideoPlay()
        } else if type == "PAUSE" {
            adActivity?.onVideoPause()
        } else if type == "ENDED" {
            adActivity?.onVideoEnd()
        }
    }
    
    private func reportOverflow(contentWidth: Int, contentHeight: Int, viewWidth: Int, viewHeight: Int) {
        print("\(Self.TAG): Ad overflow detected! Content: \(contentWidth)x\(contentHeight) > View: \(viewWidth)x\(viewHeight)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let baseAdView = self.baseAdView else { return }
            baseAdView.listener?.onAdFailedToLoad("Ad content overflow detected")
            baseAdView.destroy()
            baseAdView.removeFromSuperview()
        }
    }
    
    private func showAd() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let baseAdView = self.baseAdView else { return }
            baseAdView.webView?.isHidden = false
        }
    }
}
