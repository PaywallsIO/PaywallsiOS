import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@objc
public final class PaywallsSDK: NSObject {
    private let container: PaywallsContainer
    @objc private static var instance: PaywallsSDK?

    @objc public static var shared: PaywallsSDK {
        guard let instance = Self.instance else {
            fatalError(Definitions.paywallsNotSetup)
        }

        return instance
    }

    @objc
    public static func setup(config: PaywallsConfig) {
        guard Self.instance == nil else { return }

        let container = PaywallsContainer(config: config)
        Self.instance = PaywallsSDK(container: container)
    }

    public func sayHello() {
        container.sayHello()
    }

    // MARK: Private

    private init(container: PaywallsContainer) {
        self.container = container
    }
}
