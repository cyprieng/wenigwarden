//
//  BitwardenService.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 19/08/2024.
//

import Foundation
import Alamofire
import CommonCrypto

/// A class to interact with the Bitwarden API
class BitwardenAPI {
    static let shared = BitwardenAPI()

    var host: String?
    var accessToken: String?
    var refreshToken: String?
    var expireIn: Int?

    private init() {}

    /// Performs a prelogin to get KDF iterations
    /// - Parameter email: The user's email
    /// - Returns: A `PreloginResponse` containing KDF iterations
    public func prelogin(email: String) async throws -> PreloginResponse {
        return try await request(method: .post, path: "/identity/accounts/prelogin",
                                 encoding: JSONEncoding.default, parameters: [
                                    "email": email
                                 ], responseType: PreloginResponse.self)
    }

    /// Logs in the user and retrieves tokens and keys
    /// - Parameters:
    ///   - email: The user's email
    ///   - password: The user's password
    ///   - kdfIterations: The number of KDF iterations
    ///   - otp: OTP if needed
    /// - Returns: A `LoginResponse` containing tokens and keys
    public func login(email: String, password: String, kdfIterations: Int, otp: String? = nil) async throws -> LoginResponse {
        let masterKey = generateMasterKey(email: email, password: password, kdfIterations: kdfIterations)

        let key = pbkdf2(hash: CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256),
                         passwordData: masterKey!,
                         salt: password.data(using: .utf8)!,
                         keyByteCount: 256/8,
                         rounds: 1)

        var parameters = [
            "grant_type": "password",
            "username": email,
            "password": key!.base64EncodedString(),
            "scope": "api offline_access",
            "client_id": "browser",
            "deviceType": 7,
            "deviceIdentifier": AppState.shared.deviceId,
            "deviceName": "wenigwarden",
            "devicePushToken": ""
        ] as [String: Any]

        // Add OTP
        if otp != nil {
            parameters["twoFactorToken"] = otp
        }

        let response = try await request(method: .post, path: "/identity/connect/token",
                                         encoding: URLEncoding.default,
                                         parameters: parameters,
                                         responseType: LoginResponse.self)

        // Store tokens and expiration time
        accessToken = response.accessToken
        refreshToken = response.refreshToken
        expireIn = response.expiresIn

        return LoginResponse(
            masterKey: masterKey!,
            key: response.key,
            privateKey: response.privateKey,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn
        )
    }

    /// Synchronizes the vault with the server
    /// - Returns: A `VaultModel` containing the synchronized vault data
    public func sync() async throws -> VaultModel {
        return try await request(method: .get,
                                 path: "/api/sync",
                                 encoding: JSONEncoding.default,
                                 parameters: nil,
                                 responseType: VaultModel.self)
    }

    /// Makes a request to the Bitwarden API
    /// - Parameters:
    ///   - method: The HTTP method to use
    ///   - path: The API endpoint path
    ///   - encoding: The parameter encoding to use
    ///   - parameters: The parameters to include in the request
    ///   - responseType: The type of the response
    /// - Returns: The decoded response of type `T`
    private func request<T: Decodable>(method: HTTPMethod,
                                       path: String,
                                       encoding: ParameterEncoding,
                                       parameters: [String: Any]?,
                                       responseType: T.Type) async throws -> T {
        try await withUnsafeThrowingContinuation { continuation in
            var headers: HTTPHeaders = []
            if let token = accessToken {
                headers["Authorization"] = "Bearer \(token)"
            }

            guard let host = host else {
                continuation.resume(throwing: URLError(.badURL))
                return
            }

            let url = "\(host)\(path)"
            AF.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
                .validate()
                .responseDecodable(of: responseType) { response in
                    switch response.result {
                    case .success(let value):
                        continuation.resume(returning: value)
                    case .failure(let error):
                        // Try to parse the error message
                        if let data = response.data {
                            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                            if errorResponse != nil {
                                continuation.resume(throwing: errorResponse!)
                                return
                            }
                        }
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
}
