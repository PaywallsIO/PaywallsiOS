import Foundation

protocol IdentityRepositoryProtocol {
    var isAnonymous: Bool { get }
    var distinctId: String { get }
    var ogDistinctId: String? { get }
    func identify(_ distinctId: String)
    func fetchProperties() async throws -> [String: PaywallsValueTypeProtocol]
    func setProperties(_ properties: [String: PaywallsValueTypeProtocol])
    func setOnceProperties(_ properties: [String: PaywallsValueTypeProtocol])
    func setProperty(_ key: String, _ value: PaywallsValueTypeProtocol)
    func setOnceProperty(_ key: String, _ value: PaywallsValueTypeProtocol)
    func removeProperty(_ key: String)
    func getProperty(_ key: String) -> PaywallsValueTypeProtocol?
    func reset()
}

final class IdentityRepository: IdentityRepositoryProtocol {
    private let storageRepository: StorageRepositoryProtocol
    private let persistenceManager: PersistenceManagerProtocol
    private let dataSyncManager: DataSyncManagerProtocol
    private let identityApiClient: IdentityApiClientProtocol
    private let logger: LoggerProtocol

    private var properties: [String: PaywallsValueTypeProtocol] {
        if let properties = storageRepository.getDictionary(forKey: .userProperties) as? [String: PaywallsValueTypeProtocol] {
            return properties
        }
        return [:]
    }
    var ogDistinctId: String?
    var distinctId: String {
        if let distinctId = storageRepository.getString(forKey: .distinctId) {
            return distinctId
        }
        let annonDistinctId = generateAnonymous()
        reset(annonDistinctId)
        return annonDistinctId
    }
    var isAnonymous: Bool {
        isAnonymousId(distinctId: distinctId)
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

    func identify(_ distinctId: String) {
        guard isAnonymous else {
            logger.info("User is already identified as \(distinctId)")
            return
        }
        guard !isAnonymousId(distinctId: distinctId) else {
            logger.error("Cannot identify as anonymous user \(distinctId)")
            return
        }
        ogDistinctId = distinctId
        saveDistinctId(distinctId)
    }

    func reset() {
        reset(generateAnonymous())
    }

    func getProperty(_ key: String) -> PaywallsValueTypeProtocol? {
        properties[key]
    }

    func setProperty(_ key: String, _ value: PaywallsValueTypeProtocol) {
        var properties = properties
        properties[key] = value
        savePropertiesLocally(properties)
        enqueueOperation(set: [key: PaywallsValueType(value: value)])
    }

    func setProperties(_ props: [String: PaywallsValueTypeProtocol]) {
        let newProps = properties.merging(props, uniquingKeysWith: { _, right in right })
        savePropertiesLocally(newProps)
        enqueueOperation(set: props.mapValues({ PaywallsValueType(value: $0) }))
    }

    func setOnceProperty(_ key: String, _ value: PaywallsValueTypeProtocol) {
        guard getProperty(key) == nil else {
            return
        }

        var properties = properties
        properties[key] = value
        savePropertiesLocally(properties)

        enqueueOperation(setOnce: [key: PaywallsValueType(value: value)])
    }

    func setOnceProperties(_ props: [String: PaywallsValueTypeProtocol]) {
        let filteredProps = props.filter({ getProperty($0.key) == nil })
        let newProps = properties.merging(filteredProps, uniquingKeysWith: { _,right in right })

        savePropertiesLocally(newProps)
        enqueueOperation(setOnce: filteredProps.mapValues({ PaywallsValueType(value: $0) }))
    }

    func removeProperty(_ key: String) {
        var properties = properties
        properties[key] = nil
        savePropertiesLocally(properties)

        enqueueOperation(remove: [key])
    }

    func fetchProperties() async throws -> [String: PaywallsValueTypeProtocol] {
        do {
            let request = GetAppUserRequest(distinctId: distinctId)
            let appUser = try await identityApiClient.getAppUser(request: request)
            let propertyValues = appUser.properties.compactMapValues({ $0 as? PaywallsValueTypeProtocol })
            let newProps = properties.merging(propertyValues) { _, right in right }
            savePropertiesLocally(newProps)
            return newProps
        } catch {
            logger.error("Error getting appUser and saving properties: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Private
    private func reset(_ distinctId: String) {
        storageRepository.reset()
        ogDistinctId = nil
        setupNewUser(distinctId)
    }

    private func setupNewUser(_ distinctId: String) {
        saveDistinctId(distinctId)
        setProperties(InternalProperty.appUserProperties)
        setOnceProperties(InternalProperty.setOnceProperties)
    }

    private func savePropertiesLocally(_ properties: [String: PaywallsValueTypeProtocol]) {
        storageRepository.setDictionary(forKey: .userProperties, contents: properties)
    }

    private func saveDistinctId(_ distinctId: String) {
        storageRepository.setString(forKey: .distinctId, contents: distinctId)
    }

    private func enqueueOperation(
        set: [String: PaywallsValueType] = [:],
        setOnce: [String: PaywallsValueType] = [:],
        remove: [String] = []
    ) {
        let entity = PersistentAppUser(
            distinctId: distinctId,
            set: set,
            setOnce: setOnce,
            remove: remove
        )
        persistenceManager.insert(PersistentAppUser.self, entity)
    }

    private func generateAnonymous() -> String {
        "\(Definitions.anonymousDistinctIdPrefix)\(UUID().uuidString.lowercased())"
    }

    private func isAnonymousId(distinctId: String) -> Bool {
        distinctId.hasPrefix(Definitions.anonymousDistinctIdPrefix)
    }
}
