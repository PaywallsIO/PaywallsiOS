import Foundation

protocol SessionManagerProtocol {
    var sessionId: String? { get }

    func rotateSessionIdIfRequired()
    func rotateSession()
    func resetSession()
    func pauseSession()
}

class SessionManager: SessionManagerProtocol {
    private(set) var sessionId: String?

    private var sessionLastTimestamp: TimeInterval?
    private let sessionLock = NSLock()

    func rotateSessionIdIfRequired() {
        guard sessionId != nil, let sessionLastTimestamp else {
            rotateSession()
            return
        }

        if Date().timeIntervalSince1970 - sessionLastTimestamp > Definitions.maxSessionLength {
            rotateSession()
        }
    }

    /// Pause session when app is backgrounded
    func pauseSession() {
        sessionLock.withLock {
            sessionLastTimestamp = Date().timeIntervalSince1970
        }
    }

    func resetSession() {
        sessionLock.withLock {
            sessionId = nil
            sessionLastTimestamp = nil
        }
    }

    func rotateSession() {
        let newSessionId = UUID().uuidString
        let newSessionLastTimestamp = Date().timeIntervalSince1970

        sessionLock.withLock {
            sessionId = newSessionId
            sessionLastTimestamp = newSessionLastTimestamp
        }
    }
}
