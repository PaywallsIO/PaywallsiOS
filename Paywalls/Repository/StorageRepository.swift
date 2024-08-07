// Adapted from https://github.com/PostHog/posthog-ios/blob/main/PostHog/PostHogStorage.swift

import Foundation

enum StorageKey: String, CaseIterable {
    case distinctId = "paywalls.distinctId"
    case anonymousId = "paywalls.anonymousId"
    case queue = "paywalls.queueFolder"
}

protocol StorageRepositoryProtocol {
    func url(forKey key: StorageKey) -> URL
    func reset()
    func remove(key: StorageKey)
    func getString(forKey key: StorageKey) -> String?
    func setString(forKey key: StorageKey, contents: String)
    func getDictionary(forKey key: StorageKey) -> [AnyHashable: Any]?
    func setDictionary(forKey key: StorageKey, contents: [AnyHashable: Any])
    func getBool(forKey key: StorageKey) -> Bool?
    func setBool(forKey key: StorageKey, contents: Bool)
}

class StorageRepository: StorageRepositoryProtocol {
    private let logger: LoggerProtocol
    private let appFolderUrl: URL // The location for storing data that we always want to keep

    init(logger: LoggerProtocol) {
        self.logger = logger

        self.appFolderUrl = Self.applicationSupportDirectoryURL()
        createDirectoryAtURLIfNeeded(url: appFolderUrl)
    }

    func url(forKey key: StorageKey) -> URL {
        appFolderUrl.appendingPathComponent(key.rawValue)
    }

    func reset() {
        StorageKey.allCases.forEach {
            deleteSafely(url(forKey: $0))
        }
    }

    func remove(key: StorageKey) {
        let url = url(forKey: key)

        deleteSafely(url)
    }

    func getString(forKey key: StorageKey) -> String? {
        let value = getJson(forKey: key)
        if let stringValue = value as? String {
            return stringValue
        } else if let dictValue = value as? [String: String] {
            return dictValue[key.rawValue]
        }
        return nil
    }

    func setString(forKey key: StorageKey, contents: String) {
        setJson(forKey: key, json: contents)
    }

    func getDictionary(forKey key: StorageKey) -> [AnyHashable: Any]? {
        getJson(forKey: key) as? [AnyHashable: Any]
    }

    func setDictionary(forKey key: StorageKey, contents: [AnyHashable: Any]) {
        setJson(forKey: key, json: contents)
    }

    func getBool(forKey key: StorageKey) -> Bool? {
        let value = getJson(forKey: key)
        if let boolValue = value as? Bool {
            return boolValue
        } else if let dictValue = value as? [String: Bool] {
            return dictValue[key.rawValue]
        }
        return nil
    }

    func setBool(forKey key: StorageKey, contents: Bool) {
        setJson(forKey: key, json: contents)
    }

    // MARK: Private

    private static func applicationSupportDirectoryURL() -> URL {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return url.appendingPathComponent(Bundle.main.bundleIdentifier!)
    }

    private func createDirectoryAtURLIfNeeded(url: URL) {
        if FileManager.default.fileExists(atPath: url.path) { return }
        do {
            try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true)
        } catch {
            logger.error("Error creating storage directory: \(error)")
        }
    }

    // The "data" methods are the core for storing data and differ between Modes
    // All other typed storage methods call these
    private func getData(forKey: StorageKey) -> Data? {
        let url = url(forKey: forKey)

        do {
            if FileManager.default.fileExists(atPath: url.path) {
                return try Data(contentsOf: url)
            }
        } catch {
            logger.error("Error reading data from key \(forKey): \(error)")
        }
        return nil
    }

    private func setData(forKey: StorageKey, contents: Data?) {
        var url = url(forKey: forKey)

        do {
            if contents == nil {
                deleteSafely(url)
                return
            }

            try contents?.write(to: url)

            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try url.setResourceValues(resourceValues)
        } catch {
            logger.error("Failed to write data for key '\(forKey)' error: \(error)")
        }
    }

    private func getJson(forKey key: StorageKey) -> Any? {
        guard let data = getData(forKey: key) else { return nil }

        do {
            return try JSONSerialization.jsonObject(with: data)
        } catch {
            logger.error("Failed to serialize key '\(key)' error: \(error)")
        }
        return nil
    }

    private func setJson(forKey key: StorageKey, json: Any) {
        var jsonObject: Any?

        if let dictionary = json as? [AnyHashable: Any] {
            jsonObject = dictionary
        } else if let array = json as? [Any] {
            jsonObject = array
        } else {
            // TRICKY: This is weird legacy behaviour storing the data as a dictionary
            jsonObject = [key.rawValue: json]
        }

        var data: Data?
        do {
            data = try JSONSerialization.data(withJSONObject: jsonObject!)
        } catch {
            logger.error("Failed to serialize key '\(key)' error: \(error)")
        }
        setData(forKey: key, contents: data)
    }

    private func deleteSafely(_ file: URL) {
        if FileManager.default.fileExists(atPath: file.path) {
            do {
                try FileManager.default.removeItem(at: file)
            } catch {
                logger.error("Error trying to delete file \(file.path) \(error)")
            }
        }
    }
}
