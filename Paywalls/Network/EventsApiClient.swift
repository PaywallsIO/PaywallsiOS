import Foundation

protocol EventsApiClientProtocol {
    func logEvents(request: LogEventsRequest) async throws
    func trigger(request: TriggerRequest) async throws -> TriggerResponse?
}

enum EventsApiClientError: Error {
    case invalidResponse(statusCode: Int)
}

final class EventsApiClient: EventsApiClientProtocol {
    private let requestManager: RequestManagerProtocol
    private let dataDecoder: DataDecoderProtocol
    private let logger: LoggerProtocol // Todo: Loggers shouldn't exist inside Api clients. Move logger to a higher network layer and remove the local logger

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
        let (_, response) = try await requestManager.request(endpoint: endpoint)

        switch response.statusCode {
        case 200..<300:
            return
        default:
            throw EventsApiClientError.invalidResponse(statusCode: response.statusCode)
        }
    }

    func trigger(request: TriggerRequest) async throws -> TriggerResponse? {
        let endpoint = ApiEndpoint(
            path: "api/events/trigger",
            httpMethod: .post,
            json: request
        )
        let (data, response) = try await requestManager.request(endpoint: endpoint)

        switch response.statusCode {
        case 200:
            return try dataDecoder.decode(TriggerResponse.self, data: data)
        case 204:
            return nil
        default:
            throw EventsApiClientError.invalidResponse(statusCode: response.statusCode)
        }
    }
}
