import Foundation

protocol IdentityRepositoryProtocol {
    var isAnonymous: Bool { get }
    var distinctId: String { get }
    var anonDistinctId: String? { get }
    func identify(
        _ newDistinctId: String,
        set: [String: PaywallsValueTypeProtocol],
        setOnce: [String: PaywallsValueTypeProtocol]
    ) -> String
    func fetchProperties() async throws -> [String: PaywallsValueTypeProtocol]
    func setProperties(_ properties: [String: PaywallsValueTypeProtocol])
    func setOnceProperties(_ properties: [String: PaywallsValueTypeProtocol])
    func setProperty(_ key: String, _ value: PaywallsValueTypeProtocol)
    func setOnceProperty(_ key: String, _ value: PaywallsValueTypeProtocol)
    func unsetProperty(_ key: String)
    func getProperty(_ key: String) -> PaywallsValueTypeProtocol?
    func reset()
}

final class IdentityRepository: IdentityRepositoryProtocol {
    private let storageRepository: StorageRepositoryProtocol
    private let identityApiClient: IdentityApiClientProtocol
    private let internalProperties: InternalPropertiesProtocol
    private let logger: LoggerProtocol

    private var properties: [String: PaywallsValueTypeProtocol] {
        if let properties = storageRepository.getDictionary(forKey: .userProperties) as? [String: PaywallsValueTypeProtocol] {
            return properties
        }
        return [:]
    }
    var anonDistinctId: String?
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
        identityApiClient: IdentityApiClientProtocol,
        internalProperties: InternalPropertiesProtocol,
        logger: LoggerProtocol
    ) {
        self.storageRepository = storageRepository
        self.identityApiClient = identityApiClient
        self.internalProperties = internalProperties
        self.logger = logger
    }

    func identify(
        _ newDistinctId: String,
        set: [String: PaywallsValueTypeProtocol] = [:],
        setOnce: [String: PaywallsValueTypeProtocol] = [:]
    ) -> String {
        guard isAnonymous else {
            logger.info("User is already identified as \(distinctId)")
            return distinctId
        }
        guard !isAnonymousId(distinctId: newDistinctId) else {
            logger.error("Cannot identify as anonymous user \(distinctId)")
            return distinctId
        }
        let oldId = distinctId
        anonDistinctId = oldId
        saveDistinctId(newDistinctId)
        return oldId
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
    }

    func setProperties(_ props: [String: PaywallsValueTypeProtocol]) {
        guard !props.isEmpty else { return }
        let newProps = properties.merging(props, uniquingKeysWith: { _, right in right })
        savePropertiesLocally(newProps)
    }

    func setOnceProperty(_ key: String, _ value: PaywallsValueTypeProtocol) {
        guard getProperty(key) == nil else {
            return
        }

        var properties = properties
        properties[key] = value
        savePropertiesLocally(properties)
    }

    func setOnceProperties(_ props: [String: PaywallsValueTypeProtocol]) {
        guard !props.isEmpty else { return }
        let filteredProps = props.filter({ getProperty($0.key) == nil })
        let newProps = properties.merging(filteredProps, uniquingKeysWith: { _,right in right })

        savePropertiesLocally(newProps)
    }

    func unsetProperty(_ key: String) {
        var properties = properties
        properties[key] = nil
        savePropertiesLocally(properties)
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
        anonDistinctId = nil
        saveDistinctId(distinctId)
    }

    private func savePropertiesLocally(_ properties: [String: PaywallsValueTypeProtocol]) {
        storageRepository.setDictionary(forKey: .userProperties, contents: properties)
    }

    private func saveDistinctId(_ distinctId: String) {
        storageRepository.setString(forKey: .distinctId, contents: distinctId)
    }

    private func generateAnonymous() -> String {
        "\(Definitions.anonymousDistinctIdPrefix)\(UUID().uuidString.lowercased())"
    }

    private func isAnonymousId(distinctId: String) -> Bool {
        distinctId.hasPrefix(Definitions.anonymousDistinctIdPrefix)
    }
}
