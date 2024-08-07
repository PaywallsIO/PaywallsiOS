import Foundation

protocol AutomaticEventsManagerProtocol {
    func startSession()
    func endSession()
}

class AutomaticEventsManager: AutomaticEventsManagerProtocol {
    private let logger: LoggerProtocol
    private let scheduler: DispatchQueue
    private let eventsRepository: EventsRepositoryProtocol
    private var sessionStartDate = Date()

    init(
        eventsRepository: EventsRepositoryProtocol,
        logger: LoggerProtocol,
        scheduler: DispatchQueue
    ) {
        self.eventsRepository = eventsRepository
        self.logger = logger
        self.scheduler = scheduler
    }

    public func startSession() {
        self.sessionStartDate = Date()
    }

    public func endSession() {
        let elapsedTime = Date().timeIntervalSince1970 - sessionStartDate.timeIntervalSince1970

        eventsRepository.logEvent(InternalEvent.session, properties: [
            InternalProperty.duration.rawValue: Int(elapsedTime)
        ])
    }
}
