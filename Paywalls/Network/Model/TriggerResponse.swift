import Foundation

struct TriggerResponse: Codable {
    let paywall: Paywall

    struct Paywall: Codable {
        let name: String
        let url: String
    }
}
