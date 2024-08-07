import Foundation

protocol SessionManagerProtocol {
    func startSession()
    func endSession()
}

class SessionManager: SessionManagerProtocol {
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

    func startSession() {
        self.sessionStartDate = Date()
    }

    func endSession() {
        let elapsedTime = Date().timeIntervalSince1970 - sessionStartDate.timeIntervalSince1970
        if elapsedTime < Definitions.maxSessionLength {
            return
        }

        eventsRepository.logEvent(InternalEvent.session, properties: [
            InternalProperty.duration.rawValue: Int(elapsedTime)
        ])
    }
}
