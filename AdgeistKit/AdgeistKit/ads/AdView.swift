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

    public override var adType: String {
        get { super.adType }
        set { super.adType = newValue }
    }

    public override var adSize: AdSize {
        get { super.adSize }
        set {
            super.adSize = newValue
            super.setAdDimension(newValue)
        }
    }
    
    public override func setAdDimension(_ adSize: AdSize) {
        super.setAdDimension(adSize)
    }

    override public var intrinsicContentSize: CGSize {
        let size = adSize
        return CGSize(width: size.getWidthInPixels(), height: size.getHeightInPixels())
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        if frame.size == .zero || frame.size.width == 0 || frame.size.height == 0 {
            frame.size = intrinsicContentSize
        }
    }

    public override func loadAd(_ request: AdRequest) {
        guard !adUnitId.isEmpty else {
            listener?.onAdFailedToLoad("adUnitId is required")
            return
        }
        super.loadAd(request)
    }
}
