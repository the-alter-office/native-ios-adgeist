import UIKit

public class AdSize {
    public let width: Int
    public let height: Int
    
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
    
    // Standard ad sizes
    public static let BANNER = AdSize(width: 320, height: 50)
    public static let LARGE_BANNER = AdSize(width: 320, height: 100)
    public static let MEDIUM_RECTANGLE = AdSize(width: 300, height: 250)
    public static let FULL_BANNER = AdSize(width: 468, height: 60)
    public static let LEADERBOARD = AdSize(width: 728, height: 90)
    public static let WIDE_SKYSCRAPER = AdSize(width: 160, height: 600)
    public static let INVALID = AdSize(width: 0, height: 0)
    
    public func getWidthInPixels() -> CGFloat {
        if width == 0 { return 0 }
        let scale = UIScreen.main.scale
        return CGFloat(width) * scale / scale // Returns points
    }
    
    public func getHeightInPixels() -> CGFloat {
        if height == 0 { return 0 }
        let scale = UIScreen.main.scale
        return CGFloat(height) * scale / scale // Returns points
    }
}

extension AdSize: Equatable {
    public static func == (lhs: AdSize, rhs: AdSize) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }
}

extension AdSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}

extension AdSize: CustomStringConvertible {
    public var description: String {
        return "\(width)x\(height)"
    }
}
