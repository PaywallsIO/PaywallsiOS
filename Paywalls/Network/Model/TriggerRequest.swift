import Foundation

struct TriggerRequest: Codable {
    enum CodingKeys: String, CodingKey {
        case eventName = "event_name"
    }

    let eventName: String
}
