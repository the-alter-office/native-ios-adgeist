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
    }
    
    // WKScriptMessageHandler protocol method
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let bodyString = message.body as? String else { return }
        
        if message.name == "postMessage" {
            postMessage(json: bodyString)
        } else if message.name == "postVideoStatus" {
            postVideoStatus(json: bodyString)
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
            print("\(Self.TAG): Invalid JSON: \(json)")
            return
        }
        
        let type = jsonObject["type"] as? String ?? ""
        
        switch type {
        case "PLAY":
            adActivity?.onVideoPlay()
        case "PAUSE":
            adActivity?.onVideoPause()
        case "ENDED":
            adActivity?.onVideoEnd()
        default:
            break
        }
    }
}
