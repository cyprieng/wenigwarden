//
//  CaseInsensitiveDecoder.swift
//  wenigwarden
//
//  Created by Cyprien Guillemot on 04/01/2025.
//

/// A custom decoder that allows for case-insensitive key matching
struct CaseInsensitiveDecoder: Decoder {
    var codingPath: [any CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    let decoder: Decoder

    /// Initializes a CaseInsensitiveDecoder
    init(_ decoder: Decoder) {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
        self.userInfo = decoder.userInfo
    }

    /// Returns a keyed decoding container with case-insensitive key matching
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        let container = try decoder.container(keyedBy: type)
        return KeyedDecodingContainer(CaseInsensitiveKeyedDecodingContainer(container))
    }

    /// Returns an unkeyed decoding container
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        try decoder.unkeyedContainer()
    }

    /// Returns a single value decoding container
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        try decoder.singleValueContainer()
    }
}

/// A custom keyed decoding container that allows for case-insensitive key matching
struct CaseInsensitiveKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    var codingPath: [CodingKey] { container.codingPath }
    var allKeys: [K] { container.allKeys }

    private let container: KeyedDecodingContainer<K>

    /// Initializes a CaseInsensitiveKeyedDecodingContainer
    init(_ container: KeyedDecodingContainer<K>) {
        self.container = container
    }

    /// Checks if the container contains a key, ignoring case
    func contains(_ key: K) -> Bool {
        container.contains(key) || container.allKeys.contains {
            $0.stringValue.lowercased() == key.stringValue.lowercased()
        }
    }

    /// Decodes a nil value for a key
    func decodeNil(forKey key: K) throws -> Bool {
        try container.decodeNil(forKey: key)
    }

    /// Decodes a value for a key, ignoring case
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        if let value = try? container.decode(type, forKey: key) {
            return value
        }

        guard let matchingKey = container.allKeys.first(where: {
            $0.stringValue.lowercased() == key.stringValue.lowercased()
        }) else {
            throw DecodingError.keyNotFound(
                key,
                DecodingError.Context(codingPath: codingPath,
                                      debugDescription: "No value associated with key \(key.stringValue)"))
        }

        return try container.decode(type, forKey: matchingKey)
    }

    /// Returns a nested keyed decoding container for a key
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K)
    throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        try container.nestedContainer(keyedBy: type, forKey: key)
    }

    /// Returns a nested unkeyed decoding container for a key
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        try container.nestedUnkeyedContainer(forKey: key)
    }

    /// Returns a super decoder
    func superDecoder() throws -> Decoder {
        try container.superDecoder()
    }

    /// Returns a super decoder for a key
    func superDecoder(forKey key: K) throws -> Decoder {
        try container.superDecoder(forKey: key)
    }
}
