//
//  AdgeistCore.swift
//  AdgeistKit
//
//  Created by kishore on 02/05/25.
//

import Foundation
import Foundation

public final class AdgeistCore {
    public static let shared = AdgeistCore()
    private init() {}
    
    private let deviceIdentifier = DeviceIdentifier()
    
    public func getCreative() -> FetchCreative {
        return FetchCreative(deviceIdentifier: deviceIdentifier)
    }
    
    public func postCreativeAnalytics() -> CreativeAnalytics {
        return CreativeAnalytics(deviceIdentifier: deviceIdentifier)
    }
}
