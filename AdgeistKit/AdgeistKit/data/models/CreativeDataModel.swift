import Foundation

// Sealed protocol for ad response types
public protocol AdResponseData: Codable {}

// CPM Ad Response
public struct CPMAdResponse: Codable, AdResponseData {
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
    public let price: Double
    public let ext: BidExtension
    
    public init(id: String, impId: String, price: Double, ext: BidExtension) {
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

// Fixed Ad Response
public struct FixedAdResponse: Codable, AdResponseData {
    public let isTest: Bool?
    public let expiresAt: String?
    public let metaData: String
    public let id: String
    public let generatedAt: String?
    public let signature: String?
    public let campaignId: String?
    public let advertiser: Advertiser?
    public let type: String?
    public let loadType: String?
    public let campaignValidity: CampaignValidity?
    public let creatives: [Creative]
    public let creativesV1: [CreativeV1]
    public let displayOptions: DisplayOptions?
    public let frontendCacheDurationSeconds: Int?
    public let impressionRequirements: ImpressionRequirements?
    
    public init(
        isTest: Bool?,
        expiresAt: String?,
        metaData: String,
        id: String,
        generatedAt: String?,
        signature: String?,
        campaignId: String?,
        advertiser: Advertiser?,
        type: String?,
        loadType: String?,
        campaignValidity: CampaignValidity?,
        creatives: [Creative],
        creativesV1: [CreativeV1],
        displayOptions: DisplayOptions?,
        frontendCacheDurationSeconds: Int?,
        impressionRequirements: ImpressionRequirements?
    ) {
        self.isTest = isTest
        self.expiresAt = expiresAt
        self.metaData = metaData
        self.id = id
        self.generatedAt = generatedAt
        self.signature = signature
        self.campaignId = campaignId
        self.advertiser = advertiser
        self.type = type
        self.loadType = loadType
        self.campaignValidity = campaignValidity
        self.creatives = creatives
        self.creativesV1 = creativesV1
        self.displayOptions = displayOptions
        self.frontendCacheDurationSeconds = frontendCacheDurationSeconds
        self.impressionRequirements = impressionRequirements
    }
}

public struct Advertiser: Codable {
    public let id: String?
    public let name: String?
    public let logoUrl: String?
    
    public init(id: String?, name: String?, logoUrl: String?) {
        self.id = id
        self.name = name
        self.logoUrl = logoUrl
    }
}

public struct CampaignValidity: Codable {
    public let startTime: String?
    public let endTime: String?
    
    public init(startTime: String?, endTime: String?) {
        self.startTime = startTime
        self.endTime = endTime
    }
}

public struct Creative: Codable {
    public let contentModerationResult: MongoIdWrapper?
    public let createdAt: MongoDateWrapper?
    public let ctaUrl: String?
    public let description: String?
    public let fileName: String?
    public let fileSize: Int?
    public let fileUrl: String?
    public let thumbnailUrl: String?
    public let title: String?
    public let type: String?
    public let updatedAt: MongoDateWrapper?
    
    public init(
        contentModerationResult: MongoIdWrapper?,
        createdAt: MongoDateWrapper?,
        ctaUrl: String?,
        description: String?,
        fileName: String?,
        fileSize: Int?,
        fileUrl: String?,
        thumbnailUrl: String?,
        title: String?,
        type: String?,
        updatedAt: MongoDateWrapper?
    ) {
        self.contentModerationResult = contentModerationResult
        self.createdAt = createdAt
        self.ctaUrl = ctaUrl
        self.description = description
        self.fileName = fileName
        self.fileSize = fileSize
        self.fileUrl = fileUrl
        self.thumbnailUrl = thumbnailUrl
        self.title = title
        self.type = type
        self.updatedAt = updatedAt
    }
}

// New CreativeV1 structure
public struct CreativeV1: Codable {
    public let title: String?
    public let description: String?
    public let ctaUrl: String?
    public let primary: MediaItem?
    public let companions: [MediaItem]?
    
    public init(
        title: String?,
        description: String?,
        ctaUrl: String?,
        primary: MediaItem?,
        companions: [MediaItem]?
    ) {
        self.title = title
        self.description = description
        self.ctaUrl = ctaUrl
        self.primary = primary
        self.companions = companions
    }
}

public struct MediaItem: Codable {
    public let type: String?
    public let fileName: String?
    public let fileSize: Int?
    public let fileUrl: String?
    public let thumbnailUrl: String?
    
    public init(
        type: String?,
        fileName: String?,
        fileSize: Int?,
        fileUrl: String?,
        thumbnailUrl: String?
    ) {
        self.type = type
        self.fileName = fileName
        self.fileSize = fileSize
        self.fileUrl = fileUrl
        self.thumbnailUrl = thumbnailUrl
    }
}

public struct MongoIdWrapper: Codable {
    public let oid: String?
    
    enum CodingKeys: String, CodingKey {
        case oid = "$oid"
    }
    
    public init(oid: String?) {
        self.oid = oid
    }
}

public struct MongoDateWrapper: Codable {
    public let date: Int64?
    
    enum CodingKeys: String, CodingKey {
        case date = "$date"
    }
    
    public init(date: Int64?) {
        self.date = date
    }
}

public struct DisplayOptions: Codable {
    public let allowedFormats: [String]?
    public let dimensions: Dimensions?
    public let isResponsive: Bool?
    public let responsiveType: String?
    public let styleOptions: StyleOptions?
    
    public init(
        allowedFormats: [String]?,
        dimensions: Dimensions?,
        isResponsive: Bool?,
        responsiveType: String?,
        styleOptions: StyleOptions?
    ) {
        self.allowedFormats = allowedFormats
        self.dimensions = dimensions
        self.isResponsive = isResponsive
        self.responsiveType = responsiveType
        self.styleOptions = styleOptions
    }
}

public struct Dimensions: Codable {
    public let height: Int?
    public let width: Int?
    
    public init(height: Int?, width: Int?) {
        self.height = height
        self.width = width
    }
}

public struct StyleOptions: Codable {
    public let fontColor: String?
    public let fontFamily: String?
    
    public init(fontColor: String?, fontFamily: String?) {
        self.fontColor = fontColor
        self.fontFamily = fontFamily
    }
}

public struct ImpressionRequirements: Codable {
    public let impressionType: [String]?
    public let minViewDurationSeconds: Int?
    
    public init(impressionType: [String]?, minViewDurationSeconds: Int?) {
        self.impressionType = impressionType
        self.minViewDurationSeconds = minViewDurationSeconds
    }
}

public struct AdErrorResponse: Codable {
    public let Error: String
    public let Status: String
    
    public init(Error: String, Status: String) {
        self.Error = Error
        self.Status = Status
    }
}

public struct AdVisibilityError: Codable {
    public let errorMessage: String
    
    public init(errorMessage: String) {
        self.errorMessage = errorMessage
    }
}

public struct AdData: Codable {
    public let data: AdResponseData?
    public let error: AdVisibilityError?
    public let statusCode: Int?

    public var isSuccess: Bool {
        return error == nil && data != nil
    }

    public var errorMessage: String {
        return error?.errorMessage ?? "Unknown error occurred"
    }

    public init(data: AdResponseData?, error: AdVisibilityError?, statusCode: Int?) {
        self.data = data
        self.error = error
        self.statusCode = statusCode
    }

    enum CodingKeys: String, CodingKey {
        case data
        case error
        case statusCode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.error = try container.decodeIfPresent(AdVisibilityError.self, forKey: .error)
        self.statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode)

        // Try to decode data as CPMAdResponse or FixedAdResponse
        if let cpm = try? container.decode(CPMAdResponse.self, forKey: .data) {
            self.data = cpm
        } else if let fixed = try? container.decode(FixedAdResponse.self, forKey: .data) {
            self.data = fixed
        } else {
            self.data = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(error, forKey: .error)
        try container.encodeIfPresent(statusCode, forKey: .statusCode)
        if let cpm = data as? CPMAdResponse {
            try container.encode(cpm, forKey: .data)
        } else if let fixed = data as? FixedAdResponse {
            try container.encode(fixed, forKey: .data)
        }
    }
}
