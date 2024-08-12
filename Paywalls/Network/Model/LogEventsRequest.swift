import Foundation

struct LogEventsRequest: Codable {
    let events: [Event]

    struct Event: Codable {
        enum CodingKeys: String, CodingKey {
            case distinctId = "distinct_id"
            case eventName = "name"
            case uuid = "uuid"
            case timestamp = "timestamp"
            case properties = "properties"
        }

        let uuid: String
        let distinctId: String
        let eventName: String
        let timestamp: Int
        let properties: [String: PaywallsValueType]
    }
}
