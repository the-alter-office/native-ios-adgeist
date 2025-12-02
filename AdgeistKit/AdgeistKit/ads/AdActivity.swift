import UIKit
import WebKit

final class AdActivity {
    private static let TAG = "AdActivity"
    private static let VISIBILITY_THRESHOLD: CGFloat = 0.5
    private static let MIN_VIEW_TIME: TimeInterval = 1.0  // 1 second (1000ms)

    private weak var baseAdView: BaseAdView?
    private let postCreativeAnalytics = AdgeistCore.getInstance().postCreativeAnalytics()

    private let renderStartTime = ProcessInfo.processInfo.systemUptime

    private var mediaType: String?
    private var currentVisibilityRatio: CGFloat = 0.0
    private var isVisible = false
    private var viewStartTime: TimeInterval = 0
    private var totalViewTime: TimeInterval = 0
    private var hasViewEvent = false
    private var hasImpression = false
    private var renderTime: TimeInterval = 0

    private var playbackStartTime: TimeInterval = 0
    private var totalPlaybackTime: TimeInterval = 0
    private var hasEnded = false
    private var hasSentPlaybackEvent = false

    private var visibilityCheckWorkItem: DispatchWorkItem?
    private var scrollChangedObserver: NSKeyValueObservation?
    private var windowFocusObserver: NSObjectProtocol?

    init(baseAdView: BaseAdView) {
        self.baseAdView = baseAdView
        self.mediaType = baseAdView.mediaType
        initialize()
    }

    private func initialize() {
        setupVisibilityTracking()
    }

    private func setupVisibilityTracking() {
        guard let view = baseAdView else { return }

        // Scroll changed → recheck visibility
        scrollChangedObserver = view.superview?.observe(\.bounds, options: [.new]) { [weak self] _, _ in
            self?.checkVisibility()
        }

        // Window focus change (app foreground/background)
        windowFocusObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.onVisibilityChange(hasFocus: true) }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.onVisibilityChange(hasFocus: false) }

        checkVisibility()
    }

    func checkVisibility() {
        guard let view = baseAdView,
              let window = view.window else {
            handleVisibilityChange(isVisible: false)
            return
        }

        let visibleRect = view.convert(view.bounds, to: nil)
        let screenBounds = window.screen.bounds
        let intersection = visibleRect.intersection(screenBounds)

        guard !intersection.isEmpty else {
            handleVisibilityChange(isVisible: false)
            return
        }

        let totalArea = view.bounds.width * view.bounds.height
        guard totalArea > 0 else { return }

        let visibleArea = intersection.width * intersection.height
        currentVisibilityRatio = visibleArea / totalArea
        let newVisible = currentVisibilityRatio >= Self.VISIBILITY_THRESHOLD

        handleVisibilityChange(isVisible: newVisible)
    }

    private func handleVisibilityChange(isVisible newVisible: Bool) {
        let wasVisible = isVisible
        isVisible = newVisible

        if isVisible && !wasVisible {
            if viewStartTime == 0 {
                viewStartTime = ProcessInfo.processInfo.systemUptime
                startVisibilityCheck()
            }
            if mediaType == "video" && !hasEnded {
                resumeWebView()
                onVideoPlay()
            }
        } else if !isVisible && wasVisible {
            updateViewTime()
            stopVisibilityCheck()
            if mediaType == "video" && !hasEnded {
                pauseWebView()
                onVideoPause()
            }
        }
    }

    private func startVisibilityCheck() {
        stopVisibilityCheck()

        // Create the work item lazily to avoid capture-before-declaration
        lazy var workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            if self.isVisible && self.viewStartTime > 0 && !self.hasViewEvent {
                let timeInView = ProcessInfo.processInfo.systemUptime - self.viewStartTime
                if timeInView >= Self.MIN_VIEW_TIME {
                    self.hasViewEvent = true
                    self.baseAdView?.listener?.onAdImpression()

                    let scrollDepth = self.scrollDepth()
                    let timeToVisible = Int64((ProcessInfo.processInfo.systemUptime - self.renderStartTime) * 1000)

                    guard let baseAdView = self.baseAdView else { return }
                    let request = AnalyticsRequest.AnalyticsRequestBuilder(
                        metaData: baseAdView.metaData,
                        isTestMode: baseAdView.isTestMode
                    )
                    .trackViewableImpression(
                        timeToVisible: timeToVisible,
                        scrollDepth: scrollDepth,
                        visibilityRatio: Float(self.currentVisibilityRatio),
                        viewTime: Int64(timeInView * 1000)
                    )
                    .build()

                    self.postCreativeAnalytics.sendTrackingDataV2(analyticsRequest: request)
                    self.stopVisibilityCheck()
                }
            }

            // Reschedule if still visible and no view event
            if self.isVisible && !self.hasViewEvent {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
            }
        }

        visibilityCheckWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }

    private func stopVisibilityCheck() {
        visibilityCheckWorkItem?.cancel()
        visibilityCheckWorkItem = nil
    }

    private func scrollDepth() -> Float {
        guard let adView = baseAdView,
              let scrollView = findRootScrollView(from: adView) else { return 1.0 }

        let adLocation = adView.convert(adView.bounds.origin, to: nil).y
        let scrollLocation = scrollView.convert(scrollView.bounds.origin, to: nil).y
        let requiredScroll = adLocation - scrollLocation

        if requiredScroll <= 0 { return 1.0 }

        let currentScroll = scrollView.contentOffset.y
        var ratio = Float(currentScroll / requiredScroll)
        ratio = max(0, min(1, ratio))
        return ratio
    }

    private func findRootScrollView(from view: UIView?) -> UIScrollView? {
        var current = view?.superview
        var deepestScrollView: UIScrollView?

        while let v = current {
            if let scrollView = v as? UIScrollView {
                deepestScrollView = scrollView
            }
            current = v.superview
        }
        return deepestScrollView
    }

    private func updateViewTime() {
        if viewStartTime > 0 {
            totalViewTime += ProcessInfo.processInfo.systemUptime - viewStartTime
            viewStartTime = 0
        }
    }

    func onVisibilityChange(hasFocus: Bool) {
        if !hasFocus {
            updateViewTime()
            stopVisibilityCheck()
            if mediaType == "video" && !hasEnded {
                pauseWebView()
                onVideoPause()
            }
        } else if isVisible {
            if mediaType == "video" && !hasEnded {
                resumeWebView()
                onVideoPlay()
            }
        }
    }

    func onVideoPlay() {
        if playbackStartTime == 0 {
            playbackStartTime = ProcessInfo.processInfo.systemUptime
        }
    }

    func onVideoPause() {
        updatePlaybackTime()
    }

    func onVideoEnd() {
        if !hasEnded && mediaType == "video" {
            hasEnded = true
            updatePlaybackTime()
        }
    }

    private func updatePlaybackTime() {
        if playbackStartTime > 0 && mediaType == "video" {
            totalPlaybackTime += ProcessInfo.processInfo.systemUptime - playbackStartTime
            playbackStartTime = 0
        }
    }

    func captureImpression() {
        guard !hasImpression else { return }
        hasImpression = true

        renderTime = ProcessInfo.processInfo.systemUptime - renderStartTime
        print("\(Self.TAG): renderTime = \(renderTime * 1000)ms")

        baseAdView?.listener?.onAdLoaded()

        guard let baseAdView = baseAdView else { return }
        let request = AnalyticsRequest.AnalyticsRequestBuilder(
            metaData: baseAdView.metaData,
            isTestMode: baseAdView.isTestMode
        )
        .trackImpression(renderTime: Int64(renderTime * 1000))
        .build()

        postCreativeAnalytics.sendTrackingDataV2(analyticsRequest: request)
    }

    func captureClick() {
        baseAdView?.listener?.onAdClicked()

        guard let baseAdView = baseAdView else { return }
        let request = AnalyticsRequest.AnalyticsRequestBuilder(
            metaData: baseAdView.metaData,
            isTestMode: baseAdView.isTestMode
        )
        .trackClick()
        .build()

        postCreativeAnalytics.sendTrackingDataV2(analyticsRequest: request)
    }

    func captureTotalViewTime() {
        guard totalViewTime > 0, let baseAdView = baseAdView else { return }
        let request = AnalyticsRequest.AnalyticsRequestBuilder(
            metaData: baseAdView.metaData,
            isTestMode: baseAdView.isTestMode
        )
        .trackTotalViewTime(totalViewTime: Int64(totalViewTime * 1000))
        .build()

        postCreativeAnalytics.sendTrackingDataV2(analyticsRequest: request)
    }

    func captureTotalVideoPlaybackTime() {
        guard totalPlaybackTime > 0, !hasSentPlaybackEvent, mediaType == "video",
              let baseAdView = baseAdView else { return }

        hasSentPlaybackEvent = true
        let request = AnalyticsRequest.AnalyticsRequestBuilder(
            metaData: baseAdView.metaData,
            isTestMode: baseAdView.isTestMode
        )
        .trackTotalPlaybackTime(totalPlaybackTime: Int64(totalPlaybackTime * 1000))
        .build()

        postCreativeAnalytics.sendTrackingDataV2(analyticsRequest: request)
    }

    private var webView: WKWebView? {
        return baseAdView?.webView
    }

    private func pauseWebView() {
        webView?.evaluateJavaScript("window.adCardInstance?.pauseVideo?.()")
    }

    private func resumeWebView() {
        webView?.evaluateJavaScript("window.adCardInstance?.playVideo?.()")
    }

    func destroy() {
        stopVisibilityCheck()
        captureTotalViewTime()
        captureTotalVideoPlaybackTime()
        updateViewTime()

        scrollChangedObserver?.invalidate()
        if let observer = windowFocusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
