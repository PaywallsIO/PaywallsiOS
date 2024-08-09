import Foundation

protocol IdentityApiClientProtocol {
    func saveAppUsers(request: SaveAppUsersRequest) async throws -> SaveAppUsersResponse
    func getAppUser(request: GetAppUserRequest) async throws -> GetAppUserResponse
}

enum IdentityApiClientError: Error {
    case invalidResponse
    case notFound
}

final class IdentityApiClient: IdentityApiClientProtocol {
    private let requestManager: RequestManagerProtocol
    private let dataDecoder: DataDecoderProtocol
    private let logger: LoggerProtocol

    init(
        requestManager: RequestManagerProtocol,
        dataDecoder: DataDecoderProtocol,
        logger: LoggerProtocol
    ) {
        self.requestManager = requestManager
        self.dataDecoder = dataDecoder
        self.logger = logger
    }

    func getAppUser(request: GetAppUserRequest) async throws -> GetAppUserResponse {
        let endpoint = ApiEndpoint(
            path: "api/app_users/\(request.distinctId)",
            httpMethod: .get
        )
        let (data, response) = try await requestManager.request(endpoint: endpoint)
        switch response.statusCode {
        case 200:
            logger.verbose("getAppUser data \(String(data: data, encoding: .utf8) ?? "nil")")
            logger.verbose("getAppUser response \(response)")
            return try dataDecoder.decode(GetAppUserResponse.self, data: data)
        case 404:
            throw IdentityApiClientError.notFound
        default:
            throw IdentityApiClientError.invalidResponse
        }
    }
}
