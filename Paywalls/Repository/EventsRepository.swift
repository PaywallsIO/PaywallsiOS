import Foundation

protocol EventsRepositoryProtocol {
    func trigger(_ eventName: String) async throws -> TriggerFire?
    func logEvent(_ eventName: String, properties: [String: PaywallsValueTypeProtocol])
    func logEvent(_ eventName: String)
    func logEvent(_ internalEvent: InternalEvent)
}

protocol InternalEvent {
    var action: String { get }
    var properties: [String: PaywallsValueTypeProtocol?] { get }
}

final class EventsRepository: EventsRepositoryProtocol {
    private let logger: LoggerProtocol
    private let apiClient: EventsApiClientProtocol
    private let persistenceManager: PersistenceManagerProtocol
    private let identityRepository: IdentityRepositoryProtocol
    private let internalProperties: InternalPropertiesProtocol

    init(
        apiClient: EventsApiClientProtocol,
        persistenceManager: PersistenceManagerProtocol,
        identityRepository: IdentityRepositoryProtocol,
        internalProperties: InternalPropertiesProtocol,
        logger: LoggerProtocol
    ) {
        self.apiClient = apiClient
        self.persistenceManager = persistenceManager
        self.identityRepository = identityRepository
        self.internalProperties = internalProperties
        self.logger = logger
    }

    func trigger(_ eventName: String) async throws -> TriggerFire? {
        return try await performTrigger(eventName)
    }

    func logEvent(_ eventName: String) {
        guard eventName.trimmingCharacters(in: .whitespacesAndNewlines).first != "$" else {
            logger.warn("Event names starting with $ are reserved. \(eventName)")
            return
        }
        handleLogEvent(eventName, properties: [:])
    }

    func logEvent(_ eventName: String, properties: [String: PaywallsValueTypeProtocol]) {
        guard eventName.trimmingCharacters(in: .whitespacesAndNewlines).first != "$" else {
            logger.warn("Event names starting with $ are reserved. \(eventName)")
            return
        }
        handleLogEvent(eventName, properties: properties)
    }

    func logEvent(_ internalEvent: InternalEvent) {
        handleLogEvent(internalEvent.action, properties: internalEvent.properties)
    }

    private func performTrigger(_ eventName: String) async throws -> TriggerFire? {
        guard let triggerResponse = try await apiClient.trigger(request: .init(event: eventName)),
              let triggerFire = EventsAdapter.toTriggerFile(triggerResponse) else {
            return nil
        }
        return triggerFire
    }

    private func handleLogEvent(
        _ eventName: String,
        properties: [String: PaywallsValueTypeProtocol?]
    ) {
        let eventProperties = properties.merging(internalProperties.eventProperties) { left, _ in left }

        let entity = PersistentEvent(
            distinctId: identityRepository.distinctId,
            eventName: eventName,
            properties: eventProperties.mapValues({ PaywallsValueType(value: $0) })
        )
        persistenceManager.insert(PersistentEvent.self, entity)
    }
}
