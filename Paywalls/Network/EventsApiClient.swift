import Foundation

protocol EventsApiClientProtocol {
    func logEvents(request: LogEventsRequest) async throws -> LogEventsResponse
}

enum EventsApiClientError: Error {
    case invalidResponse(statusCode: Int)
}

final class EventsApiClient: EventsApiClientProtocol {
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

    func logEvents(request: LogEventsRequest) async throws -> LogEventsResponse {
        let endpoint = ApiEndpoint(
            path: "api/v1/app/events",
            httpMethod: .post,
            json: request
        )
        let (data, response) = try await requestManager.request(endpoint: endpoint)
        switch response.statusCode {
        case 200..<300:
            logger.verbose("logEvent data \(String(data: data, encoding: .utf8) ?? "nil")")
            logger.verbose("logEvent response \(response)")
            return try dataDecoder.decode(LogEventsResponse.self, data: data)
        default:
            throw EventsApiClientError.invalidResponse(statusCode: response.statusCode)
        }
    }
}
