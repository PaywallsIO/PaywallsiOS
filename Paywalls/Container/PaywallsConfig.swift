import Foundation

@objc(PaywallsConfig)
public final class PaywallsConfig: NSObject {
    @objc public let host: URL
    @objc public let apiKey: String
    @objc public var logLevel: LogLevel = .warn
    @objc public var eventFlushIntervalSeconds: TimeInterval = 30

    @objc(apiKey:)
    public init(apiKey: String) {
        self.host = Definitions.defaultHostUrl
        self.apiKey = apiKey
    }

    @objc(apiKey:host:)
    public init(
        apiKey: String,
        host: String
    ) {
        self.apiKey = apiKey
        self.host = URL(string: host) ?? Definitions.defaultHostUrl
    }
}
