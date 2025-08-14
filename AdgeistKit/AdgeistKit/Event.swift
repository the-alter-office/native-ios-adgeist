import Foundation

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
    
    // Custom encoding/decoding for [String: Any]
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventType, forKey: .eventType)
        if let eventProperties = eventProperties {
            let data = try JSONSerialization.data(withJSONObject: eventProperties, options: [])
            let decoded = try JSONDecoder().decode([String: AnyCodable].self, from: data)
            try container.encode(decoded, forKey: .eventProperties)
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
