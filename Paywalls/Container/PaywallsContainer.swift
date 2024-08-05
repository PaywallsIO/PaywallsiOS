import Foundation

protocol PaywallsContainerProtocol {}

final class PaywallsContainer: PaywallsContainerProtocol {
    static func makeContainer(from config: PaywallsConfig) -> any PaywallsContainerProtocol {
        PaywallsContainer(config: config)
    }

    private let config: PaywallsConfig

    init(config: PaywallsConfig) {
        self.config = config
    }
}
