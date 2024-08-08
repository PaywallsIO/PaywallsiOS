import Foundation

public protocol PaywallsValueTypeProtocol: Any {}

public struct PaywallsValueType: Codable {
    let value: PaywallsValueTypeProtocol?

    init(value: PaywallsValueTypeProtocol?) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = nil
        } else if let stringValue = try? container.decode(String.self) {
            self.value = stringValue
        } else if let intValue = try? container.decode(Int.self) {
            self.value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            self.value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            self.value = boolValue
        } else if let floatValue = try? container.decode(Float.self) {
            self.value = floatValue
        } else if let dateValue = try? container.decode(Date.self) {
            self.value = dateValue
        } else if let arrayValue = try? container.decode([PaywallsValueType].self) {
            self.value = arrayValue.map ({ $0.value })
        } else if let dictionaryValue = try? container.decode([String: PaywallsValueType].self) {
            self.value = dictionaryValue.mapValues({ $0.value })
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid data"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        guard let value else {
            try container.encodeNil()
            return
        }

        if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let floatValue = value as? Float {
            try container.encode(floatValue)
        } else if let dateValue = value as? Date {
            try container.encode(dateValue)
        } else if let arrayValue = value as? [PaywallsValueTypeProtocol] {
            let values = arrayValue.compactMap({ PaywallsValueType(value: $0) })
            try container.encode(values)
        } else if let dictionaryValue = value as? [String: PaywallsValueTypeProtocol] {
            let values = dictionaryValue.compactMapValues({ PaywallsValueType(value: $0) })
            try container.encode(values)
        } else {
            let type = type(of: value)
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Cannot encode the value: \(value) of type \(type)"
                )
            )
        }
    }
}

// Helper type for decoding dictionaries with arbitrary keys
struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    init(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

extension String: PaywallsValueTypeProtocol {}
extension Int: PaywallsValueTypeProtocol {}
extension Double: PaywallsValueTypeProtocol {}
extension Bool: PaywallsValueTypeProtocol {}
extension Float: PaywallsValueTypeProtocol {}
extension Date: PaywallsValueTypeProtocol {}
extension Array: PaywallsValueTypeProtocol {}
extension Dictionary: PaywallsValueTypeProtocol {}
