//
//  Extensions.swift
//  AdgeistKit
//
//  Created by kishore on 14/08/25.
//

import Foundation

extension Date {
    func toISOString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
