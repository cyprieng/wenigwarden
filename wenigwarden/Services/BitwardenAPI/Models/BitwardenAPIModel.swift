//
//  BitwardenServiceModel.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 22/08/2024.
//

import Foundation

/// Model representing the response from the prelogin request
struct PreloginResponse: Decodable {
    let kdfIterations: Int

    /// Coding keys for decoding
    enum CodingKeys: String, CodingKey {
        case kdfIterations
    }

    /// Initializer for decoding a PreloginResponse
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
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
