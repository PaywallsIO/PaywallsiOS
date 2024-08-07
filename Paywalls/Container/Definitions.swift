import Foundation

struct Definitions {
    static let appName = "Paywalls"
    static let defaultHostUrl = URL(string: "https://api.paywalls.io")!
    static let paywallsNotSetup = "PaywallsSDK not set up. Call PaywallsSDK.setup(config:) first."
    static let sessionThresholdSeconds = 60 * 60 // 1 hour
}
