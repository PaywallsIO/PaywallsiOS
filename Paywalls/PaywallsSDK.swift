import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@objc
public final class PaywallsSDK: NSObject {
    private let container: PaywallsContainerProtocol
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
        
        let container = ContainerFactory.makeContainer(from: config)
        Self.instance = PaywallsSDK(container: container)
    }

    private init(container: PaywallsContainerProtocol) {
        self.container = container
    }
}
