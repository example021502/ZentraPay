import Foundation

/// A wrapper that makes arbitrary JSON-compatible values conform to `Encodable`.
/// Used to bridge `[String: Any]` dictionaries from Flutter into generic `Encodable` parameters.
struct AnyCodable: Encodable {
  let value: Any

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch value {
    case let v as String: try container.encode(v)
    case let v as Bool: try container.encode(v)
    case let v as Int: try container.encode(v)
    case let v as Double: try container.encode(v)
    case let v as [String: Any]: try container.encode(v.mapValues { AnyCodable(value: $0) })
    case let v as [Any]: try container.encode(v.map { AnyCodable(value: $0) })
    default: try container.encodeNil()
    }
  }
}
