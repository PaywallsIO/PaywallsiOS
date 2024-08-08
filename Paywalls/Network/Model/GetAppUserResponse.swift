import Foundation

struct GetAppUserResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case distinctId = "distinct_id"
        case createdAt = "created_at"
        case aliases = "aliases"
        case properties = "properties"
    }

    let distinctId: String
    let aliases: [String]?
    let properties: [String: PaywallsValueType]
    let createdAt: Date
}
