import Foundation
import UIKit

final class PaywallsContainer {
    private let config: PaywallsConfig
    private let logger: LoggerProtocol

    lazy var internalProperties = buildInternalProperties()
    lazy var storageRepository = buildStorageRepository()
    lazy var eventsRepository = buildEventsRepository()
    lazy var identityRepository = buildIdentityRepository()

    lazy var essionManager = buildSessionManager()
    lazy var requestManager = buildRequestManager()
    lazy var persistenceManager = buildPersistenceManager()
    lazy var dataSyncManager = buildDataSyncManager()
    lazy var lifeCycleManager = buildLifeCycleManager()
    lazy var sessionManager = buildSessionManager()

    lazy var identityApiClient = buildIdentityApiClient()
    lazy var eventsApiClient = buildEventsApiClient()

    lazy var dataDecoder = buildDataDecoder()

    private let syncQueue = DispatchQueue(label: "io.paywalls.sync", qos: .utility, attributes: .concurrent, autoreleaseFrequency: .workItem)

    private var triggerTask: Task<Void, Never>?

    deinit {
        triggerTask?.cancel()
    }

    init(
        config: PaywallsConfig
    ) {
        self.config = config
        self.logger = Logger(logLevel: config.logLevel)

        sessionManager.rotateSession()
        lifeCycleManager.register()
        dataSyncManager.startTimer()
    }

    func capture(_ eventName: String, _ properties: [String: PaywallsValueTypeProtocol] = [:]) {
        eventsRepository.logEvent(eventName, properties: properties)
    }

    func identify(
        _ distinctId: String,
        set: [String: PaywallsValueTypeProtocol] = [:],
        setOnce: [String: PaywallsValueTypeProtocol] = [:]
    ) {
        let anonDistinctId = identityRepository.identify(
            distinctId,
            set: set,
            setOnce: setOnce
        )
        eventsRepository.logEvent(InternalEvents.Identify(
            anonDistinctId: anonDistinctId,
            set: set,
            setOnce: setOnce,
            unset: []
        ))
    }

    func reset() {
        identityRepository.reset()
    }

    func trigger(_ eventName: String, presentingViewController: UIViewController? = nil) {
        triggerTask?.cancel()
        triggerTask = Task { @MainActor [weak self, eventsRepository] in
            do {
                if let triggerFire = try await eventsRepository.trigger(eventName) {
                    self?.handleTriggerFire(triggerFire, presentingViewController)
                }
            } catch {
                self?.logger.error(error.localizedDescription)
            }
        }
    }

    func makePaywallViewModel(coordinator: PaywallCoordinatorProtocol, triggerFire: TriggerFire) -> some PaywallViewModelProtocol {
        PaywallViewModel(coordinator: coordinator, triggerFire: triggerFire)
    }

    // MARK: Private

    private func handleTriggerFire(_ triggerFire: TriggerFire, _ presentingViewController: UIViewController?) {
        let coordinator = buildPaywallCoordiantor(triggerFire: triggerFire)

        let presentingViewController = presentingViewController ?? UIHelper.topViewController
        presentingViewController?.present(coordinator.instinateRoot(), animated: true)
    }

    private func buildDataSyncManager() -> DataSyncManagerProtocol {
        CacheSyncManager(
            logger: logger,
            eventsApiClient: eventsApiClient,
            identityApiClient: identityApiClient,
            persistenceManager: persistenceManager,
            syncQueue: syncQueue,
            syncInterval: Definitions.syncInterval,
            batchSize: Definitions.batchSize
        )
    }

    private func buildPaywallCoordiantor(triggerFire: TriggerFire) -> PaywallCoordinatorProtocol {
        PaywallCoordinator(container: self, triggerFire: triggerFire)
    }

    private func buildSessionManager() -> SessionManagerProtocol {
        SessionManager()
    }

    private func buildLifeCycleManager() -> LifeCycleManagerProtocol {
        LifeCycleManager(
            logger: logger,
            dataSyncManager: dataSyncManager,
            sessionManager: sessionManager,
            eventRepository: eventsRepository
        )
    }

    private func buildEventsApiClient() -> EventsApiClientProtocol {
        EventsApiClient(
            requestManager: requestManager,
            dataDecoder: dataDecoder,
            logger: logger
        )
    }

    private func buildRequestManager() -> RequestManagerProtocol {
        URLSessionRequestManager(
            baseURL: config.host,
            bearerToken: config.apiKey,
            logger: logger
        )
    }

    private func buildPersistenceManager() -> PersistenceManagerProtocol {
        SqlitePersistenceManager(
            databaseFileName: Definitions.libName,
            persistableModels: [
                PersistentEvent.self
            ],
            logger: logger
        )
    }

    private func buildIdentityApiClient() -> IdentityApiClientProtocol {
        IdentityApiClient(
            requestManager: requestManager,
            dataDecoder: dataDecoder,
            logger: logger
        )
    }

    private func buildStorageRepository() -> StorageRepositoryProtocol {
        StorageRepository(logger: logger)
    }

    private func buildIdentityRepository() -> IdentityRepositoryProtocol {
        IdentityRepository(
            storageRepository: storageRepository,
            identityApiClient: identityApiClient,
            internalProperties: internalProperties,
            logger: logger
        )
    }

    private func buildEventsRepository() -> EventsRepositoryProtocol {
        EventsRepository(
            apiClient: eventsApiClient,
            persistenceManager: persistenceManager,
            identityRepository: identityRepository,
            internalProperties: internalProperties,
            logger: logger
        )
    }

    private func buildInternalProperties() -> InternalPropertiesProtocol {
        InternalProperties(sessionManager: sessionManager)
    }

    private func buildDataDecoder() -> DataDecoderProtocol {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return DataDecoder(dateFormatter: dateFormatter)
    }
}
