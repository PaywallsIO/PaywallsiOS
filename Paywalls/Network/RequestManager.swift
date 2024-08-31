import Foundation
import Combine

// MARK: Protocols

protocol RequestManagerProtocol {
    var baseURL: URL { get }
    var bearerToken: String? { get }

    @discardableResult
    func request(endpoint: ApiEndpoint) async throws -> (Data, HTTPURLResponse)
}

protocol ApiEndpointProtocol {
    var path: String { get }
    var httpMethod: RequestMethod { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
}

enum RequestMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum RequestManagerError: Error {
    case invalidUrl
    case invalidResponse
    case notAuthorized
    case unknownError(_ statusCode: Int, _ description: String)
}

struct ApiEndpoint: ApiEndpointProtocol {
    let path: String
    let httpMethod: RequestMethod
    let headers: [String: String]?
    let body: Data?
    let queryItems: [URLQueryItem]

    init(path: String, httpMethod: RequestMethod) {
        self.path = path
        self.httpMethod = httpMethod
        self.headers = nil
        self.body = nil
        self.queryItems = []
    }

    init(path: String, httpMethod: RequestMethod, json: Encodable) {
        self.path = path
        self.httpMethod = httpMethod
        self.headers = ["Content-Type": "application/json"]
        self.body = try! JSONEncoder().encode(json)
        self.queryItems = []
    }

    init(path: String, httpMethod: RequestMethod, queryItems: [URLQueryItem]) {
        self.path = path
        self.httpMethod = httpMethod
        self.queryItems = queryItems
        self.body = nil
        self.headers = [:]
    }
}

class URLSessionRequestManager: RequestManagerProtocol {
    let logger: LoggerProtocol
    let baseURL: URL
    let bearerToken: String?

    init(
        baseURL: URL,
        bearerToken: String,
        logger: LoggerProtocol
    ) {
        self.baseURL = baseURL
        self.bearerToken = bearerToken
        self.logger = logger
    }

    func request(endpoint: ApiEndpoint) async throws -> (Data, HTTPURLResponse) {
        let url = baseURL.appendingPathComponent(endpoint.path)
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw RequestManagerError.invalidUrl
        }

        if endpoint.queryItems.count > 0 {
            urlComponents.queryItems = endpoint.queryItems
        }
        guard let fullURL = urlComponents.url else {
            throw RequestManagerError.invalidUrl
        }

        var urlRequest = URLRequest(url: fullURL)
        urlRequest.httpMethod = endpoint.httpMethod.rawValue
        urlRequest.httpBody = endpoint.body
        urlRequest.allHTTPHeaderFields = endpoint.headers

        if let token = bearerToken {
            urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let response = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response.1 as? HTTPURLResponse else {
                throw RequestManagerError.invalidResponse
            }
            return (response.0, httpResponse)
        } catch {
            logger.error(error.localizedDescription)
            throw error
        }
    }
}
