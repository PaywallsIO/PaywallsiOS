import Foundation

struct ContainerFactory {
    static func makeContainer(from config: PaywallsConfig) -> any PaywallsContainerProtocol {
        PaywallsContainer(config: config)
    }
}
