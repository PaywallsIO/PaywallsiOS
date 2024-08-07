import Foundation

protocol DataDecoderProtocol {
    func decode<T: Decodable>(_ type: T.Type, data: Data) throws -> T
}

final class DataDecoder: DataDecoderProtocol {
    private let dateFormatter: DateFormatter
    private let decoder: JSONDecoder

    init(
        dateFormatter: DateFormatter,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.dateFormatter = dateFormatter
        self.decoder = decoder
    }

    func decode<T: Decodable>(_ type: T.Type, data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return try decoder.decode(T.self, from: data)
    }
}
