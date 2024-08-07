import Foundation

struct SaveAppUsersResponse: Codable {
    let processed: [Int]
    let errors: [String: [String]]
}
