import Foundation

protocol SessionManagerProtocol {
    func getAnonymousId() -> String
}

final class SessionRepository: SessionManagerProtocol {
    private let storage: StorageRepositoryProtocol

    private let anonLock = NSLock()
    private let distinctLock = NSLock()

    init(storage: StorageRepositoryProtocol) {
        self.storage = storage
    }

    func getAnonymousId() -> String {
        var anonymousId: String?
        anonLock.withLock {
            anonymousId = storage.getString(forKey: .anonymousId)

            if anonymousId == nil {
                anonymousId = UUID().uuidString
                setAnonId(anonymousId ?? "")
            }
        }

        return anonymousId ?? ""
    }

    public func setAnonymousId(_ id: String) {
        anonLock.withLock {
            setAnonId(id)
        }
    }

    private func setAnonId(_ id: String) {
        storage.setString(forKey: .anonymousId, contents: id)
    }

    public func getDistinctId() -> String {
        var distinctId: String?
        distinctLock.withLock {
            distinctId = storage.getString(forKey: .distinctId) ?? getAnonymousId()
        }
        return distinctId ?? ""
    }

    public func setDistinctId(_ id: String) {
        distinctLock.withLock {
            storage.setString(forKey: .distinctId, contents: id)
        }
    }

    public func reset() {
        distinctLock.withLock {
            storage.remove(key: .distinctId)
        }
        anonLock.withLock {
            storage.remove(key: .anonymousId)
        }
    }
}
