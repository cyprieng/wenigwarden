//
//  CaseInsensitiveDecoder.swift
//  wenigwarden
//
//  Created by Cyprien Guillemot on 04/01/2025.
//
import Foundation

// Custom Key Type to handle both string and integer keys
struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    // Initialize with a string value
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    // Initialize with an integer value
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}

// CaseInsensitiveDecoder that wraps a standard Decoder and provides case-insensitive key handling
struct CaseInsensitiveDecoder: Decoder {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    private let decoder: Decoder

    // Initialize with a standard decoder
    init(_ decoder: Decoder) {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
        self.userInfo = decoder.userInfo
    }

    // Return a case-insensitive keyed decoding container
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        // Get the container using AnyCodingKey
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        // Wrap it in a CaseInsensitiveKeyedDecodingContainer
        let caseInsensitiveContainer = CaseInsensitiveKeyedDecodingContainer<Key>(container: container)
        return KeyedDecodingContainer(caseInsensitiveContainer)
    }

    // Return an unkeyed container
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        try decoder.unkeyedContainer()
    }

    // Return a single value container
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        try decoder.singleValueContainer()
    }
}

// Keyed decoding container that performs case-insensitive key lookups
struct CaseInsensitiveKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    var codingPath: [CodingKey]
    var allKeys: [K]

    private let container: KeyedDecodingContainer<AnyCodingKey>
    private var keyMap: [String: AnyCodingKey] = [:]

    // Initialize with a keyed decoding container
    init(container: KeyedDecodingContainer<AnyCodingKey>) {
        self.container = container
        self.codingPath = container.codingPath
        self.allKeys = []
        self.populateKeyMap()
    }

    // Populate the key map with lowercased versions of the keys for case-insensitive lookups
    private mutating func populateKeyMap() {
        for key in container.allKeys {
            // Map lowercased key strings to their respective AnyCodingKey
            keyMap[key.stringValue.lowercased()] = key
            // Convert AnyCodingKey to the original key type
            if let newKey = K(stringValue: key.stringValue) {
                allKeys.append(newKey)
            }
        }
    }

    // Check if the container contains a value for the given key
    func contains(_ key: K) -> Bool {
        keyMap.keys.contains(key.stringValue.lowercased())
    }

    // Decode a nil value for the given key
    func decodeNil(forKey key: K) throws -> Bool {
        if let matchingKey = keyMap[key.stringValue.lowercased()] {
            return try container.decodeNil(forKey: matchingKey)
        }
        return try container.decodeNil(forKey: AnyCodingKey(stringValue: key.stringValue)!)
    }

    // Decode a value of the specified type for the given key
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        if let matchingKey = keyMap[key.stringValue.lowercased()] {
            return try container.decode(type, forKey: matchingKey)
        }
        return try container.decode(type, forKey: AnyCodingKey(stringValue: key.stringValue)!)
    }

    // Decode a nested container for the given key
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K)
    throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        if let matchingKey = keyMap[key.stringValue.lowercased()] {
            return try container.nestedContainer(keyedBy: type, forKey: matchingKey)
        }
        return try container.nestedContainer(keyedBy: type, forKey: AnyCodingKey(stringValue: key.stringValue)!)
    }

    // Decode a nested unkeyed container for the given key
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        if let matchingKey = keyMap[key.stringValue.lowercased()] {
            return try container.nestedUnkeyedContainer(forKey: matchingKey)
        }
        return try container.nestedUnkeyedContainer(forKey: AnyCodingKey(stringValue: key.stringValue)!)
    }

    // Return a decoder for super (parent) data
    func superDecoder() throws -> Decoder {
        return try container.superDecoder()
    }

    // Return a decoder for super (parent) data for the given key
    func superDecoder(forKey key: K) throws -> Decoder {
        if let matchingKey = keyMap[key.stringValue.lowercased()] {
            return try container.superDecoder(forKey: matchingKey)
        }
        return try container.superDecoder(forKey: AnyCodingKey(stringValue: key.stringValue)!)
    }
}
