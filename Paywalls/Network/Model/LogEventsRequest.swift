import Foundation

struct LogEventsRequest: Codable {
    let events: [Event]

    struct Event: Codable {
        enum CodingKeys: String, CodingKey {
            case localId = "local_id"
            case appUserId = "app_user_id"
            case ogAppUserId = "og_app_user_id"
            case eventName = "event_name"
            case eventTime = "event_time"
            case properties = "properties"
        }

        let localId: Int
        let appUserId: String
        let ogAppUserId: String?
        let eventName: String
        let eventTime: Date
        let properties: [String: PaywallsValueType]
    }
}
