import Foundation

protocol IdentityRepositoryProtocol {
    var isAnonymous: Bool { get }
    var appUserId: String { get }
    var ogAppUserId: String? { get }
    func identify(_ appUserId: String)
    func fetchProperties() async throws -> [String: PaywallsValueType]
    func setProperty(_ key: String, _ value: PaywallsValueType)
    func setOnceProperty(_ key: String, _ value: PaywallsValueType)
    func removeProperty(_ key: String)
    func getProperty(_ key: String) -> PaywallsValueType?
    func reset()
}

final class IdentityRepository: IdentityRepositoryProtocol {
    private let storageRepository: StorageRepositoryProtocol
    private let persistenceManager: PersistenceManagerProtocol
    private let dataSyncManager: DataSyncManagerProtocol
    private let identityApiClient: IdentityApiClientProtocol
    private let logger: LoggerProtocol

    private var properties: [String: PaywallsValueType] {
        if let properties = storageRepository.getDictionary(forKey: .userProperties) as? [String: PaywallsValueType] {
            return properties
        }
        return [:]
    }
    var ogAppUserId: String?
    var appUserId: String {
        if let userId = storageRepository.getString(forKey: .userId) {
            return userId
        }
        let annonUserId = generateAnonymous()
        reset(annonUserId)
        return annonUserId
    }
    var isAnonymous: Bool {
        isAnonymousId(userId: appUserId)
    }

    init(
        storageRepository: StorageRepositoryProtocol,
        persistenceManager: PersistenceManagerProtocol,
        identityApiClient: IdentityApiClientProtocol,
        dataSyncManager: DataSyncManagerProtocol,
        logger: LoggerProtocol
    ) {
        self.storageRepository = storageRepository
        self.persistenceManager = persistenceManager
        self.identityApiClient = identityApiClient
        self.dataSyncManager = dataSyncManager
        self.logger = logger
    }

    func identify(_ userId: String) {
        guard isAnonymous else {
            logger.info("User is already identified as \(appUserId)")
            return
        }
        guard !isAnonymousId(userId: userId) else {
            logger.error("Cannot identify as anonymous user \(userId)")
            return
        }
        ogAppUserId = appUserId
        saveUserId(userId)
    }

    func reset() {
        reset(generateAnonymous())
    }

    func getProperty(_ key: String) -> PaywallsValueType? {
        properties[key]
    }

    func setProperty(_ key: String, _ value: PaywallsValueType) {
        var properties = properties
        properties[key] = value
        savePropertiesLocally(properties)
        enqueueOperation(set: [key: value])
    }

    func setProperties(_ props: [String: PaywallsValueType]) {
        let newProps = properties.merging(props, uniquingKeysWith: { _, right in right })
        savePropertiesLocally(newProps)
        enqueueOperation(set: props)
    }

    func setOnceProperty(_ key: String, _ value: PaywallsValueType) {
        guard getProperty(key) == nil else {
            return
        }

        var properties = properties
        properties[key] = value
        savePropertiesLocally(properties)

        enqueueOperation(setOnce: [key: value])
    }

    func setOnceProperties(_ props: [String: PaywallsValueType]) {
        let filteredProps = props.filter({ getProperty($0.key) == nil })
        let newProps = properties.merging(filteredProps, uniquingKeysWith: { _,right in right })

        savePropertiesLocally(newProps)
        enqueueOperation(setOnce: filteredProps)
    }

    func removeProperty(_ key: String) {
        var properties = properties
        properties[key] = nil
        savePropertiesLocally(properties)

        enqueueOperation(remove: [key])
    }

    func fetchProperties() async throws -> [String: PaywallsValueType] {
        do {
            let request = GetAppUserRequest(appUserId: appUserId)
            let appUser = try await identityApiClient.getAppUser(request: request)
            let propertyValues = appUser.properties.mapValues({ $0 as PaywallsValueType })
            let newProps = properties.merging(propertyValues) { _, right in right }
            savePropertiesLocally(newProps)
            return newProps
        } catch {
            logger.error("Error getting appUser and saving properties: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Private
    private func reset(_ username: String) {
        storageRepository.reset()
        ogAppUserId = nil
        setupNewUser(username)
    }

    private func setupNewUser(_ username: String) {
        saveUserId(username)
        setProperties(InternalProperty.appUserProperties)
        setOnceProperties(InternalProperty.setOnceProperties)
    }

    private func savePropertiesLocally(_ properties: [String: PaywallsValueType]) {
        storageRepository.setDictionary(forKey: .userProperties, contents: properties.mapValues { $0.value })
    }

    private func saveUserId(_ userId: String) {
        storageRepository.setString(forKey: .userId, contents: userId)
    }

    private func enqueueOperation(
        set: [String: PaywallsValueType] = [:],
        setOnce: [String: PaywallsValueType] = [:],
        remove: [String] = []
    ) {
        let entity = PersistentAppUser(
            appUserId: appUserId,
            set: set,
            setOnce: setOnce,
            remove: remove
        )
        persistenceManager.insert(PersistentAppUser.self, entity)
    }

    private func generateAnonymous() -> String {
        "\(Definitions.anonymousUserIdPrefix)\(UUID().uuidString.lowercased())"
    }

    private func isAnonymousId(userId: String) -> Bool {
        userId.hasPrefix(Definitions.anonymousUserIdPrefix)
    }
}
