import Foundation

struct Definitions {
    static let libName = "Paywalls"
    static let libVersion = "0.1.0"

    static let defaultHostUrl = URL(string: "http://localhost")!
    static let anonymousDistinctIdPrefix = "$annon:"
    static let paywallsNotSetup = "PaywallsSDK not set up. Call PaywallsSDK.setup(config:) first."
    static let maxSessionLength = 60.0 * 60.0 // 1 hour
    static let syncInterval = 60.0
    static let batchSize = 200
}
