import Foundation

protocol DataSyncManagerProtocol {
    func preformSync()
    func startTimer()
    func stopTimer()
    func syncAppUsers() async
    func syncEvents() async
}

final class CacheSyncManager: DataSyncManagerProtocol {
    private let logger: LoggerProtocol
    private let eventsApiClient: EventsApiClientProtocol
    private let identityApiClient: IdentityApiClientProtocol
    private let persistenceManager: PersistenceManagerProtocol
    private let syncQueue: DispatchQueue
    private var syncTimer: Timer?
    private let syncInterval: Double
    private let batchSize: Int

    init(
        logger: LoggerProtocol,
        eventsApiClient: EventsApiClientProtocol,
        identityApiClient: IdentityApiClientProtocol,
        persistenceManager: PersistenceManagerProtocol,
        syncQueue: DispatchQueue,
        syncInterval: Double,
        batchSize: Int
    ) {
        self.logger = logger
        self.eventsApiClient = eventsApiClient
        self.identityApiClient = identityApiClient
        self.persistenceManager = persistenceManager
        self.syncQueue = syncQueue
        self.syncInterval = syncInterval
        self.batchSize = batchSize
    }

    func startTimer() {
        stopTimer()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.syncTimer = Timer.scheduledTimer(
                timeInterval: self.syncInterval,
                target: self,
                selector: #selector(preformSync),
                userInfo: nil,
                repeats: true
            )
            self.logger.debug("Starting sync timer")
        }
    }

    func stopTimer() {
        guard let syncTimer else { return }

        DispatchQueue.main.async { [weak self, syncTimer] in
            syncTimer.invalidate()
            self?.syncTimer = nil
            self?.logger.debug("Stoping sync timer")
        }
    }

    @objc func preformSync() {
        syncQueue.async {
            self.preformSyncInQueue()
        }
    }

    private func preformSyncInQueue() {
        Task {
            await syncEvents()
            await syncAppUsers()
        }
    }

    func syncEvents() async {
        let events = persistenceManager.getAll(PersistentEvent.self, limit: batchSize, offset: 0)
        let request = LogEventsRequest(events: events.map({
            .init(
                localId: $0.id,
                distinctId: $0.data.distinctId,
                ogDistinctId: $0.data.ogDistinctId,
                eventName: $0.data.eventName,
                eventTime: $0.createdAt,
                properties: $0.data.properties
            )
        }))
        do {
            let response = try await eventsApiClient.logEvents(request: request)
            processEventsResponse(response)
        } catch {
            logger.error("Error sending events to server: \(error.localizedDescription)")
        }
    }

    func syncAppUsers() async {
        let appUsers = persistenceManager.getAll(PersistentAppUser.self, limit: batchSize, offset: 0)
        let request = SaveAppUsersRequest(appUsers: appUsers.map({
            .init(
                localId: $0.id,
                distinctId: $0.data.distinctId,
                set: $0.data.set,
                setOnce: $0.data.setOnce,
                remove: $0.data.remove
            )
        }))
        do {
            let response = try await identityApiClient.saveAppUsers(request: request)
            processAppUsersResponse(response)
        } catch {
            logger.error("Error sending profiles to server: \(error.localizedDescription)")
        }
    }

    private func processAppUsersResponse(_ response: SaveAppUsersResponse) {
        persistenceManager.delete(PersistentAppUser.self, requests: response.processed.map({
            .init(id: $0)
        }))
    }

    private func processEventsResponse(_ response: LogEventsResponse) {
        persistenceManager.delete(PersistentEvent.self, requests: response.processed.map({
            .init(id: $0)
        }))
    }
}
