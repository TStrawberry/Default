import Foundation

/// A type that provides the fallback value for a `@DefaultProperty` wrapper.
public protocol DecodeDefaultValue {
    associatedtype T: Decodable
    static var defaultValue: T { get }
}

/// A property wrapper that decodes leniently using a `DecodeDefaultValue` type.
///
/// Apply `@Default` to mark a property and `@DefaultDecodable` on the enclosing
/// struct to generate the private default-value type and attach this wrapper.
///
/// ```swift
/// @DefaultDecodable
/// struct User: Decodable {
///     @Default("default name")
///     var name: String
/// }
/// ```
@propertyWrapper
public struct DefaultProperty<D: DecodeDefaultValue>: Decodable {
    public var wrappedValue: D.T

    public init(wrappedValue: D.T) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: any Decoder) throws {
        self.wrappedValue = (try? decoder.singleValueContainer().decode(D.T.self)) ?? D.defaultValue
    }
}

extension DefaultProperty: Encodable where D.T: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

extension KeyedDecodingContainer {
    public func decode<D: DecodeDefaultValue>(
        _ type: DefaultProperty<D>.Type,
        forKey key: KeyedDecodingContainer<K>.Key
    ) throws -> DefaultProperty<D> {
        let defaultResult = DefaultProperty<D>(wrappedValue: D.defaultValue)
        guard contains(key) else {
            return defaultResult
        }
        return try decodeIfPresent(type, forKey: key) ?? defaultResult
    }
}

extension DefaultProperty: Equatable where D.T: Equatable { }
