import Foundation

protocol ReachabilityManagerProtocol {
    var isWifi: Bool? { get }
    var isCellular: Bool? { get }
}

final class ReachabilityManager: ReachabilityManagerProtocol {
    private let reachability: Reachability?
    private let logger: LoggerProtocol

    init(logger: LoggerProtocol) {
        self.logger = logger
        do {
            self.reachability = try Reachability()
        } catch {
            self.reachability = nil
            logger.error("Reachability error: \(error.localizedDescription)")
        }
    }



    var isWifi: Bool? {
        reachability?.connection == .wifi
    }

    var isCellular: Bool? {
        reachability?.connection == .cellular
    }
}
