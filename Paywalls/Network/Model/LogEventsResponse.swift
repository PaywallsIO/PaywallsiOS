import Foundation

struct LogEventsResponse: Codable {
    let processed: [Int]
    let errors: [String: [String]]
}
