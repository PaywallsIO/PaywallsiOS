import Foundation

struct PersistentEvent: PersistenceModel {
    static let entityName = "events"

    enum CodingKeys: String, CodingKey {
        case distinctId = "distinct_id"
        case ogDistinctId = "og_distinct_id"
        case eventName = "event_name"
        case properties = "properties"
    }

    let distinctId: String
    let ogDistinctId: String?
    let eventName: String
    let properties: [String: PaywallsValueType]
}
