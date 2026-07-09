import SwiftUI
import AdgeistKit

// MARK: - UIViewRepresentable Wrapper
struct AdViewContainer: UIViewRepresentable {
    let adUnitId: String
    let adType: AdType
    let adSize: AdSize?
    let isResponsive: Bool
    let onEvent: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onEvent: onEvent)
    }

    func makeUIView(context: Context) -> AdView {
        print("AdViewContainer: Creating AdView for unit ID: \(adUnitId)")
        let adView = AdView()
        adView.adUnitId = adUnitId
        adView.adType = adType
        adView.adIsResponsive = isResponsive

        if let adSize = adSize, !isResponsive {
            adView.setAdDimension(adSize)
        }

        adView.setAdListener(context.coordinator)

        let request = AdRequest.AdRequestBuilder()
            .build()

        adView.loadAd(request)

        return adView
    }

    func updateUIView(_ uiView: AdView, context: Context) {}

    static func dismantleUIView(_ uiView: AdView, coordinator: Coordinator) {
        uiView.destroy()
    }

    class Coordinator: AdListener {
        let onEvent: (String) -> Void

        init(onEvent: @escaping (String) -> Void) {
            self.onEvent = onEvent
        }

        override func onAdLoaded() {
            print("AdView: Ad Loaded Successfully!")
            onEvent("loaded")
        }

        override func onAdFailedToLoad(_ errorMessage: String) {
            print("AdView: Ad Failed to Load: \(errorMessage)")
            onEvent("failed:\(errorMessage)")
        }

        override func onAdClicked() {
            print("AdView: Ad Clicked")
            onEvent("clicked")
        }

        override func onAdImpression() {
            print("AdView: Ad Impression")
            onEvent("impression")
        }

        override func onAdOpened() {
            print("AdView: Ad Opened")
        }

        override func onAdClosed() {
            print("AdView: Ad Closed")
        }
    }
}
