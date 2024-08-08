import Foundation

struct PersistentAppUser: PersistenceModel {
    static let entityName = "app_users"

    enum CodingKeys: String, CodingKey {
        case distinctId = "distinct_id"
        case set = "set"
        case setOnce = "set_once"
        case remove = "remove"
    }

    let distinctId: String
    let set: [String: PaywallsValueType]
    let setOnce: [String: PaywallsValueType]
    let remove: [String]
}
