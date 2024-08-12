import Foundation

protocol EventsApiClientProtocol {
    func logEvents(request: LogEventsRequest) async throws
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

    func logEvents(request: LogEventsRequest) async throws {
        let endpoint = ApiEndpoint(
            path: "api/events/ingest",
            httpMethod: .post,
            json: request
        )
        let (data, response) = try await requestManager.request(endpoint: endpoint)
        logger.verbose("logEvent data \(String(data: try! JSONEncoder().encode(request), encoding: .utf8) ?? "nil")")

        switch response.statusCode {
        case 200..<300:
            logger.verbose("logEvent response \(response)")
        default:
            throw EventsApiClientError.invalidResponse(statusCode: response.statusCode)
        }
    }
}
