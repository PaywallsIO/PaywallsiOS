import Foundation

protocol EventsRepositoryProtocol {
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
    private let persistenceManager: PersistenceManagerProtocol
    private let identityRepository: IdentityRepositoryProtocol
    private let internalProperties: InternalPropertiesProtocol

    init(
        persistenceManager: PersistenceManagerProtocol,
        identityRepository: IdentityRepositoryProtocol,
        internalProperties: InternalPropertiesProtocol,
        logger: LoggerProtocol
    ) {
        self.persistenceManager = persistenceManager
        self.identityRepository = identityRepository
        self.internalProperties = internalProperties
        self.logger = logger
    }

    func logEvent(_ eventName: String) {
        guard eventName.trimmingCharacters(in: .whitespacesAndNewlines).first != "$" else {
            logger.warn("Event names starting with $ are reserved. \(eventName)")
            return
        }
        _logEvent(eventName, properties: [:])
    }

    func logEvent(_ eventName: String, properties: [String: PaywallsValueTypeProtocol]) {
        guard eventName.trimmingCharacters(in: .whitespacesAndNewlines).first != "$" else {
            logger.warn("Event names starting with $ are reserved. \(eventName)")
            return
        }
        _logEvent(eventName, properties: properties)
    }

    func logEvent(_ internalEvent: InternalEvent) {
        _logEvent(internalEvent.action, properties: internalEvent.properties)
    }

    private func _logEvent(
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
