import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@objc
@objcMembers
public final class PaywallsSDK: NSObject {
    private let container: PaywallsContainer
    @objc private static var instance: PaywallsSDK?

    public static var shared: PaywallsSDK {
        guard let instance = Self.instance else {
            fatalError(Definitions.paywallsNotSetup)
        }

        return instance
    }

    public static func setup(config: PaywallsConfig) {
        guard Self.instance == nil else { return }

        let container = PaywallsContainer(config: config)
        Self.instance = PaywallsSDK(container: container)
    }

    public func capture(_ eventName: String, _ properties: [String: PaywallsValueTypeProtocol] = [:]) {
        container.capture(eventName, properties)
    }

    public func identify(_ distinctId: String) {
        container.identify(distinctId)
    }

    public func reset() {
        container.reset()
    }

    // MARK: Private

    private init(container: PaywallsContainer) {
        self.container = container
    }
}
