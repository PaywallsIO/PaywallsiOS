import Foundation

struct PersistentEvent: PersistenceModel {
    static let entityName = "events"

    enum CodingKeys: String, CodingKey {
        case appUserId = "app_user_id"
        case ogAppUserId = "og_app_user_id"
        case eventName = "event_name"
        case properties = "properties"
    }

    let appUserId: String
    let ogAppUserId: String?
    let eventName: String
    let properties: [String: PaywallsValueType]
}
