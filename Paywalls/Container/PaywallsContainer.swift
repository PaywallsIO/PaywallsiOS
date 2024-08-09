import Foundation

final class PaywallsContainer {
    private let config: PaywallsConfig
    private let logger: LoggerProtocol

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

    init(
        config: PaywallsConfig
    ) {
        self.config = config
        self.logger = Logger(logLevel: config.logLevel)

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
        identityRepository.identify(
            distinctId,
            set: set,
            setOnce: setOnce
        )
        eventsRepository.logEvent(InternalEvents.Identify(
            set: set,
            setOnce: setOnce,
            unset: []
        ))
    }

    func reset() {
        identityRepository.reset()
    }

    // MARK: Private

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

    private func buildSessionManager() -> SessionManagerProtocol {
        SessionManager(
            eventsRepository: eventsRepository,
            logger: logger,
            scheduler: DispatchQueue.main
        )
    }

    private func buildLifeCycleManager() -> LifeCycleManagerProtocol {
        LifeCycleManager(
            logger: logger,
            dataSyncManager: dataSyncManager,
            sessionManager: sessionManager
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
            logger: logger
        )
    }

    private func buildEventsRepository() -> EventsRepositoryProtocol {
        EventsRepository(
            persistenceManager: persistenceManager,
            identityRepository: identityRepository,
            logger: logger
        )
    }

    private func buildDataDecoder() -> DataDecoderProtocol {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return DataDecoder(dateFormatter: dateFormatter)
    }
}
