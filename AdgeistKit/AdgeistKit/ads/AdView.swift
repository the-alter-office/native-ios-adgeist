import UIKit


public final class AdView: BaseAdView {
    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public override var adUnitId: String {
        get { super.adUnitId }
        set { super.adUnitId = newValue }
    }

    public override var appID: String? {
        get { super.appID }
        set { super.appID = newValue }
    }

    public override var customOrigin: String? {
        get { super.customOrigin }
        set { super.customOrigin = newValue }
    }

    public override var adType: String {
        get { super.adType }
        set { super.adType = newValue }
    }

    public override var adSize: AdSize? {
        get { super.adSize }
        set {
            super.adSize = newValue
            super.setAdDimension(newValue ?? AdSize(width: 320, height: 100))
        }
    }
    
    public override func setAdDimension(_ adSize: AdSize) {
        super.setAdDimension(adSize)
    }

    // MARK: - Layout
    override public var intrinsicContentSize: CGSize {
        guard let size = adSize else { return CGSize(width: 320, height: 100) }
        return CGSize(width: size.getWidthInPixels(), height: size.getHeightInPixels())
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        if frame.size == .zero || frame.size.width == 0 || frame.size.height == 0 {
            frame.size = intrinsicContentSize
        }
    }

    // MARK: - Load with validation
    public override func loadAd(_ request: AdRequest) {
        guard !adUnitId.isEmpty else {
            listener?.onAdFailedToLoad("adUnitId is required")
            return
        }
        super.loadAd(request)
    }
}
