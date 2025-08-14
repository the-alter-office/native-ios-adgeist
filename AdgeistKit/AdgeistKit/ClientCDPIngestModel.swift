import Foundation

public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = ()
        } else if let boolVal = try? container.decode(Bool.self) {
            self.value = boolVal
        } else if let intVal = try? container.decode(Int.self) {
            self.value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            self.value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            self.value = stringVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            self.value = arrayVal.map { $0.value }
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            self.value = dictVal.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON type")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is Void:
            try container.encodeNil()
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let stringVal as String:
            try container.encode(stringVal)
        case let arrayVal as [Any]:
            try container.encode(arrayVal.map { AnyCodable($0) })
        case let dictVal as [String: Any]:
            try container.encode(dictVal.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "Invalid JSON value"
            ))
        }
    }
}

public struct Event: Codable {
    public let eventType: String
    public let eventProperties: [String: Any]?
    
    public init(eventType: String, eventProperties: [String: Any]? = nil) {
        self.eventType = eventType
        self.eventProperties = eventProperties
    }
    
    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case eventProperties = "event_properties"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventType, forKey: .eventType)
        if let eventProperties = eventProperties {
            try container.encode(eventProperties.mapValues { AnyCodable($0) }, forKey: .eventProperties)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.eventType = try container.decode(String.self, forKey: .eventType)
        if let decoded = try? container.decode([String: AnyCodable].self, forKey: .eventProperties) {
            self.eventProperties = decoded.mapValues { $0.value }
        } else {
            self.eventProperties = nil
        }
    }
}

public struct UserDetails: Codable {
    public let userId: String?
    public let userName: String?
    public let email: String?
    public let phone: String?
    
    public init(userId: String? = nil,
                userName: String? = nil,
                email: String? = nil,
                phone: String? = nil,
            ) {
        self.userId = userId
        self.userName = userName
        self.email = email
        self.phone = phone
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case email
        case phone
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(userName, forKey: .userName)
        try container.encode(email, forKey: .email)
        try container.encode(phone, forKey: .phone)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decodeIfPresent(String.self, forKey: .userId)
        self.userName = try container.decodeIfPresent(String.self, forKey: .userName)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.phone = try container.decodeIfPresent(String.self, forKey: .phone)
    }
    
    public func toDictionary() -> [String: Any] {
        var map: [String: Any] = [
            "user_id": userId as Any,
            "user_name": userName as Any,
            "email": email as Any,
            "phone": phone as Any
        ]
        return map
    }
}

