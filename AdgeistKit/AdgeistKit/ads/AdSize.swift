import UIKit

public class AdSize {
    public let width: Int
    public let height: Int
    
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
    
    public func getWidthInPixels() -> CGFloat {
        if width == 0 { return 0 }
        let scale = UIScreen.main.scale
        return CGFloat(width) * scale / scale
    }
    
    public func getHeightInPixels() -> CGFloat {
        if height == 0 { return 0 }
        let scale = UIScreen.main.scale
        return CGFloat(height) * scale / scale
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
