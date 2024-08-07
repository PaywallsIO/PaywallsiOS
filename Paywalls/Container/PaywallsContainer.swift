import Foundation

final class PaywallsContainer {
    private let config: PaywallsConfig
    private let logger: LoggerProtocol

    lazy var storageRepository: StorageRepositoryProtocol = makeStorageRepository()

    init(
        config: PaywallsConfig
    ) {
        self.config = config
        self.logger = Logger(logLevel: config.logLevel)
    }

    func sayHello() {
        logger.info("hello")
    }

    // MARK: Private

    private func makeStorageRepository() -> StorageRepositoryProtocol {
        StorageRepository(logger: logger)
    }
}
