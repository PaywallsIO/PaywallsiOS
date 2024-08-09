import Foundation

struct PersistentEvent: PersistenceModel {
    static let entityName = "events"

    enum CodingKeys: String, CodingKey {
        case distinctId = "distinct_id"
        case oldDistinctId = "old_distinct_id"
        case eventName = "event_name"
        case properties = "properties"
    }

    let distinctId: String
    let oldDistinctId: String?
    let eventName: String
    let properties: [String: PaywallsValueType]
}
