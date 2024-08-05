import Foundation

public struct PaywallsEvent: Codable {
    public var id: UUID
    public var name: String
    public var distinctId: String
    public var properties: [String: PaywallsValueType]
    public var timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case distinctId
        case properties
        case timestamp
    }

    public init(
        id: UUID,
        name: String,
        distinctId: String,
        properties: [String: PaywallsValueType]? = nil,
        timestamp: Date
    ) {
        self.id = id
        self.name = name
        self.distinctId = distinctId
        self.properties = properties ?? [:]
        self.timestamp = timestamp
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(distinctId, forKey: .distinctId)
        try container.encode(properties, forKey: .properties)
        try container.encode(timestamp, forKey: .timestamp)
    }
}
