import Foundation

struct GetAppUserResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case appUserId = "app_user_id"
        case createdAt = "created_at"
        case aliases = "aliases"
        case properties = "properties"
    }

    let appUserId: String
    let aliases: [String]?
    let properties: [String: PaywallsValueType]
    let createdAt: Date
}
