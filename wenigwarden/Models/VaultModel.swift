//
//  VaultModel.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 20/08/2024.
//

import Foundation

/// Model representing the vault
struct VaultModel: Codable {
    var ciphers: [CipherModel]
    var profile: Profile

    /// Coding keys for encoding and decoding
    enum CodingKeys: String, CodingKey {
        case ciphers
        case profile
    }

    /// Initializer for creating a new vault model
    init(ciphers: [CipherModel], profile: Profile) {
        self.ciphers = ciphers
        self.profile = profile
    }

    /// Initializer for decoding a vault model
    init(from decoder: Decoder) throws {
        let caseInsensitiveDecoder = CaseInsensitiveDecoder(decoder)
        let container = try caseInsensitiveDecoder.container(keyedBy: CodingKeys.self)
        ciphers = try container.decode([CipherModel].self, forKey: .ciphers)
        profile = try container.decode(Profile.self, forKey: .profile)
    }
}

/// Model representing the login information
struct Login: Codable {
    var username: String?
    var password: String?
    var totp: String?
    var uri: String?
    var uris: [Uris]?

    /// Coding keys for encoding and decoding
    enum CodingKeys: String, CodingKey {
        case username
        case password
        case totp
        case uri
        case uris
    }

    /// Initializer for creating a new login model
    init(username: String?, password: String?, totp: String?, uri: String?, uris: [Uris]?) {
        self.username = username
        self.password = password
        self.totp = totp
        self.uri = uri
        self.uris = uris
    }

    /// Initializer for decoding a login model
    init(from decoder: Decoder) throws {
        let caseInsensitiveDecoder = CaseInsensitiveDecoder(decoder)
        let container = try caseInsensitiveDecoder.container(keyedBy: CodingKeys.self)
        username = try? container.decode(String.self, forKey: .username)
        password = try? container.decode(String.self, forKey: .password)
        totp = try? container.decode(String.self, forKey: .totp)
        uri = try container.decode(String.self, forKey: .uri)
        uris = try container.decode([Uris].self, forKey: .uris)
    }
}

/// Model representing a URI
struct Uris: Codable {
    var uri: String

    /// Coding keys for encoding and decoding
    enum CodingKeys: String, CodingKey {
        case uri
    }

    /// Initializer for creating a new URI model
    init(uri: String) {
        self.uri = uri
    }

    /// Initializer for decoding a URI model
    init(from decoder: Decoder) throws {
        let caseInsensitiveDecoder = CaseInsensitiveDecoder(decoder)
        let container = try caseInsensitiveDecoder.container(keyedBy: CodingKeys.self)
        uri = try container.decode(String.self, forKey: .uri)
    }
}

/// Model representing the user profile
struct Profile: Codable {
    var organizations: [Organization]

    /// Coding keys for encoding and decoding
    enum CodingKeys: String, CodingKey {
        case organizations
    }

    /// Initializer for creating a new profile model
    init(organizations: [Organization]) {
        self.organizations = organizations
    }

    /// Initializer for decoding a profile model
    init(from decoder: Decoder) throws {
        let caseInsensitiveDecoder = CaseInsensitiveDecoder(decoder)
        let container = try caseInsensitiveDecoder.container(keyedBy: CodingKeys.self)
        organizations = try container.decode([Organization].self, forKey: .organizations)
    }
}

/// Model representing an organization
struct Organization: Codable {
    let id: String
    let key: String

    /// Coding keys for encoding and decoding
    enum CodingKeys: String, CodingKey {
        case id
        case key
    }

    /// Initializer for creating a new organization model
    init(id: String, key: String) {
        self.id = id
        self.key = key
    }

    /// Initializer for decoding an organization model
    init(from decoder: Decoder) throws {
        let caseInsensitiveDecoder = CaseInsensitiveDecoder(decoder)
        let container = try caseInsensitiveDecoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        key = try container.decode(String.self, forKey: .key)
    }
}
