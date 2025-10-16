//
//  CreativeDataModel.swift
//  AdgeistKit
//
//  Created by kishore on 02/05/25.
//

import Foundation

public struct CreativeDataModel: Codable {
    public let success: Bool
    public let message: String
    public let data: BidResponseData?
    
    public init(success: Bool, message: String, data: BidResponseData?) {
        self.success = success
        self.message = message
        self.data = data
    }
}

public struct BidResponseData: Codable {
    public let id: String
    public let seatBid: [SeatBid]
    public let bidId: String
    public let cur: String
    
    public init(id: String, seatBid: [SeatBid], bidId: String, cur: String) {
        self.id = id
        self.seatBid = seatBid
        self.bidId = bidId
        self.cur = cur
    }
}

public struct SeatBid: Codable {
    public let bidId: String
    public let bid: [Bid]
    
    public init(bidId: String, bid: [Bid]) {
        self.bidId = bidId
        self.bid = bid
    }
}

public struct Bid: Codable {
    public let id: String
    public let impId: String
    public let price: Double?
    public let ext: BidExtension
    
    public init(id: String, impId: String, price: Double?, ext: BidExtension) {
        self.id = id
        self.impId = impId
        self.price = price
        self.ext = ext
    }
}

public struct BidExtension: Codable {
    public let creativeUrl: String
    public let ctaUrl: String
    public let creativeTitle: String
    public let creativeDescription: String
    
    public init(creativeUrl: String, ctaUrl: String, creativeTitle: String, creativeDescription: String) {
        self.creativeUrl = creativeUrl
        self.ctaUrl = ctaUrl
        self.creativeTitle = creativeTitle
        self.creativeDescription = creativeDescription
    }
}
