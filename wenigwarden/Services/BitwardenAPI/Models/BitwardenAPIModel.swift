//
//  BitwardenServiceModel.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 22/08/2024.
//

import Foundation

/// Model for Bitwarden errors
struct ErrorResponse: Decodable, Error {
    let errorDescription: String?
    let twoFactorProviders: [TwoFactorProvider]?

    enum CodingKeys: String, CodingKey {
        case errorDescription = "error_description"
        case twoFactorProviders = "TwoFactorProviders"
    }

    enum TwoFactorProvider: Decodable {
        case integer(Int)
        case string(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let intValue = try? container.decode(Int.self) {
                self = .integer(intValue)
            } else if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else {
                throw DecodingError.typeMismatch(TwoFactorProvider.self, DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected Int or String"
                ))
            }
        }

        var stringValue: String {
            switch self {
            case .integer(let int):
                return String(int)
            case .string(let str):
                return str
            }
        }
    }
}

/// Model representing the response from the prelogin request
struct PreloginResponse: Decodable {
    let kdfIterations: Int

    /// Coding keys for decoding
    enum CodingKeys: String, CodingKey {
        case kdfIterations
    }

    /// Initializer for decoding a PreloginResponse
    init(from decoder: Decoder) throws {
        let caseInsensitiveDecoder = CaseInsensitiveDecoder(decoder)
        let container = try caseInsensitiveDecoder.container(keyedBy: CodingKeys.self)
        kdfIterations = try container.decode(Int.self, forKey: .kdfIterations)
    }
}

/// Model representing the response from the login request
struct LoginResponse: Decodable {
    let masterKey: Data?
    let key: String
    let privateKey: String
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int

    /// Coding keys for decoding
    enum CodingKeys: String, CodingKey {
        case masterKey
        case key = "Key"
        case privateKey = "PrivateKey"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

/// Model representing the response from the refresh token request
struct RefreshTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String

    /// Coding keys for decoding
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

/// Model representing the response from an attachment request
struct AttachmentResponse: Decodable {
    let url: String
    let key: String

    /// Coding keys for decoding
    enum CodingKeys: String, CodingKey {
        case url
        case key
    }

    /// Initializer for decoding an AttachmentResponse
    init(from decoder: Decoder) throws {
        let caseInsensitiveDecoder = CaseInsensitiveDecoder(decoder)
        let container = try caseInsensitiveDecoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(String.self, forKey: .url)
        key = try container.decode(String.self, forKey: .key)
    }
}
