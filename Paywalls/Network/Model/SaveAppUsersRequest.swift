import Foundation

struct SaveAppUsersRequest: Codable {
    let appUsers: [AppUser]

    struct AppUser: Codable {
        enum CodingKeys: String, CodingKey {
            case localId = "local_id"
            case appUserId = "app_user_id"
            case set = "set"
            case setOnce = "set_once"
            case remove = "remove"
        }

        let localId: Int
        let appUserId: String
        let set: [String: PaywallsValueType]
        let setOnce: [String: PaywallsValueType]
        let remove: [String]
    }
}
