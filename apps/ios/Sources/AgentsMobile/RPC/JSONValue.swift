import Foundation

/// A small JSON value representation used by Craft Agents' WebSocket RPC envelopes.
enum JSONValue: Codable, Equatable, Sendable {
  case array([JSONValue])
  case bool(Bool)
  case null
  case number(Double)
  case object([String: JSONValue])
  case string(String)

  init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()

    if container.decodeNil() {
      self = .null
    } else if let bool = try? container.decode(Bool.self) {
      self = .bool(bool)
    } else if let number = try? container.decode(Double.self) {
      self = .number(number)
    } else if let string = try? container.decode(String.self) {
      self = .string(string)
    } else if let array = try? container.decode([JSONValue].self) {
      self = .array(array)
    } else {
      self = try .object(container.decode([String: JSONValue].self))
    }
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()

    switch self {
    case let .array(array):
      try container.encode(array)
    case let .bool(bool):
      try container.encode(bool)
    case .null:
      try container.encodeNil()
    case let .number(number):
      try container.encode(number)
    case let .object(object):
      try container.encode(object)
    case let .string(string):
      try container.encode(string)
    }
  }
}

extension JSONValue {
  static func encode(_ value: some Encodable) throws -> JSONValue {
    let data = try JSONEncoder.craftRPC.encode(value)
    return try JSONDecoder.craftRPC.decode(JSONValue.self, from: data)
  }

  func decode<T: Decodable>(_ type: T.Type = T.self) throws -> T {
    let data = try JSONEncoder.craftRPC.encode(self)
    return try JSONDecoder.craftRPC.decode(T.self, from: data)
  }
}

extension JSONDecoder {
  static let craftRPC: JSONDecoder = {
    let decoder = JSONDecoder()
    return decoder
  }()
}

extension JSONEncoder {
  static let craftRPC: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return encoder
  }()
}
