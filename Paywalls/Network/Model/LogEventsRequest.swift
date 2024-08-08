import Foundation

struct LogEventsRequest: Codable {
    let events: [Event]

    struct Event: Codable {
        enum CodingKeys: String, CodingKey {
            case localId = "local_id"
            case distinctId = "distinct_id"
            case ogDistinctId = "og_distinct_id"
            case eventName = "event_name"
            case eventTime = "event_time"
            case properties = "properties"
        }

        let localId: Int
        let distinctId: String
        let ogDistinctId: String?
        let eventName: String
        let eventTime: Date
        let properties: [String: PaywallsValueType]
    }
}
