import Foundation

protocol DataSyncManagerProtocol {
    func preformSync()
    func startTimer()
    func stopTimer()
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
        }
    }

    func syncEvents() async {
        let events = persistenceManager.getAll(PersistentEvent.self, limit: batchSize, offset: 0)
        let request = LogEventsRequest(events: events.map({
            .init(
                uuid: $0.data.uuid,
                distinctId: $0.data.distinctId,
                oldDistinctId: $0.data.oldDistinctId,
                eventName: $0.data.eventName,
                timestamp: Int($0.createdAt.timeIntervalSince1970),
                properties: $0.data.properties
            )
        }))
        do {
            try await eventsApiClient.logEvents(request: request)
            deleteEvents(events.map(\.id))
        } catch {
            logger.error("Error sending events to server: \(error.localizedDescription)")
        }
    }

    private func deleteEvents(_ eventIds: [Int]) {
        persistenceManager.delete(PersistentEvent.self, requests: eventIds.map({
            .init(id: $0)
        }))
    }
}
