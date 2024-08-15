import Foundation

struct TriggerRequest: Codable {
    enum CodingKeys: String, CodingKey {
        case event = "event"
    }

    let event: String
}
