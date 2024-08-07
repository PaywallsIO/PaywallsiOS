import Foundation

@objc public enum LogLevel: Int {
    case verbose = 0
    case debug = 1
    case info = 2
    case warn = 3
    case error = 4

    var stringValue: String {
        switch self {
        case .warn: return "WARN"
        case .debug: return "DEBUG"
        case .error: return "ERROR"
        case .info: return "INFO"
        case .verbose: return "VERBOSE"
        }
    }

    var emojii: Character {
        switch self {
        case .warn: return "🟡"
        case .debug: return "⚪️"
        case .error: return "🔴"
        case .info: return "🔵"
        case .verbose: return "🟣"
        }
    }
}

protocol LoggerProtocol {
    var logLevel: LogLevel { get }
    func warn(_ message: String)
    func info(_ message: String)
    func debug(_ message: String)
    func error(_ message: String)
    func verbose(_ message: String)
}

final class Logger: LoggerProtocol {
    let logLevel: LogLevel

    init(logLevel: LogLevel) {
        self.logLevel = logLevel
    }

    func warn(_ message: String) {
        log(.warn, message)
    }

    func info(_ message: String) {
        log(.info, message)
    }

    func debug(_ message: String) {
        log(.debug, message)
    }

    func error(_ message: String) {
        log(.error, message)
    }

    func verbose(_ message: String) {
        log(.verbose, message)
    }

    private func log(_ level: LogLevel, _ message: String) {
        guard level.rawValue >= logLevel.rawValue else {
            return
        }
        print("[\(Definitions.libName)] 💸 \(level.stringValue) \(level.emojii): \(message)")
    }
}
