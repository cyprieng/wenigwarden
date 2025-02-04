//
//  BitwardenService.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 19/08/2024.
//

import Foundation
import Alamofire
import CommonCrypto
import KeychainAccess

/// A class to interact with the Bitwarden API
final class BitwardenAPI {
    static let shared = BitwardenAPI()

    // Host
    private var host: BitwardenHost?
    private var selfHostedURL: String?

    // Tokens
    private var accessToken: String?
    private var refreshToken: String?

    // Keychain to store refresh token
    private var keychain: Keychain

    // Store two factor provider
    // Basic implementation that should be improved to support multiple
    var twoFactorProvider: String?

    /// Init Bitwarden API
    private init() {
        keychain = Keychain(service: "io.cyprien.wenigwarden")
        refreshToken = try? keychain.get("refreshToken")
    }

    /// Set host
    public func setHost(host: BitwardenHost, url: String? = nil) {
        self.host = host
        self.selfHostedURL = url
    }

    /// Performs a prelogin to get KDF iterations
    /// - Parameter email: The user's email
    /// - Returns: A `PreloginResponse` containing KDF iterations
    internal func prelogin(email: String) async throws -> PreloginResponse {
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
    internal func login(email: String,
                        password: String,
                        kdfIterations: Int,
                        otp: String? = nil) async throws -> LoginResponse {
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

            if let provider = twoFactorProvider, !provider.isEmpty {
                parameters["twoFactorProvider"] = provider
            }
        }

        let response = try await request(method: .post, path: "/identity/connect/token",
                                         encoding: URLEncoding.default,
                                         headers: ["Auth-Email": email.data(using: .utf8)?.base64EncodedString() ?? ""],
                                         parameters: parameters,
                                         responseType: LoginResponse.self)

        // Store tokens and expiration time
        accessToken = response.accessToken
        refreshToken = response.refreshToken
        keychain["refreshToken"] = refreshToken

        return LoginResponse(
            masterKey: masterKey!,
            key: response.key,
            privateKey: response.privateKey,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn
        )
    }

    /// Refresh access token using refresh token
    internal func refreshAccessToken(_ refreshToken: String)  async throws {
        let response = try await request(method: .post, path: "/identity/connect/token",
                                         encoding: URLEncoding.default,
                                         parameters: [
                                            "grant_type": "refresh_token",
                                            "client_id": "browser",
                                            "refresh_token": refreshToken
                                         ],
                                         responseType: RefreshTokenResponse.self)

        // Store tokens and expiration time
        accessToken = response.accessToken
        self.refreshToken = response.refreshToken
        keychain["refreshToken"] = refreshToken
    }

    /// Get attachment data
    internal func getAttachmentData(cipherId: String, attachmentId: String) async throws -> AttachmentResponse {
        let response = try await request(method: .get, path: "/api/ciphers/\(cipherId)/attachment/\(attachmentId)",
                                         encoding: URLEncoding.default,
                                         parameters: nil,
                                         responseType: AttachmentResponse.self)

        return response
    }

    /// Synchronizes the vault with the server
    /// - Returns: A `VaultModel` containing the synchronized vault data
    internal func sync() async throws -> VaultModel {
        return try await request(method: .get,
                                 path: "/api/sync",
                                 encoding: JSONEncoding.default,
                                 parameters: nil,
                                 responseType: VaultModel.self)
    }

    /// Build API headers
    private func buildHeaders(_ headers: HTTPHeaders) -> HTTPHeaders {
        var newHeaders = headers // Créer une copie mutable
        if let token = accessToken {
            newHeaders["Authorization"] = "Bearer \(token)"
        }
        return newHeaders
    }

    /// Build request url
    /// - Parameters:
    ///   - path: The API endpoint path
    private func buildRequestURL(path: String) -> String? {
        guard let host = host else { return nil }

        var hostStr: String = ""
        if host == .com {
            hostStr = "https://vault.bitwarden.com"
        } else if host == .eu {
            hostStr = "https://vault.bitwarden.eu"
        } else if host == .selfHosted {
            guard let url = selfHostedURL else { return nil }
            hostStr = url
        }

        return "\(hostStr)\(path)"
    }

    /// Makes a request to the Bitwarden API
    /// - Parameters:
    ///   - method: The HTTP method to use
    ///   - path: The API endpoint path
    ///   - encoding: The parameter encoding to use
    ///   - headers: headers to send
    ///   - parameters: The parameters to include in the request
    ///   - responseType: The type of the response
    /// - Returns: The decoded response of type `T`
    private func request<T: Decodable>(method: HTTPMethod,
                                       path: String,
                                       encoding: ParameterEncoding,
                                       headers: HTTPHeaders = [],
                                       parameters: [String: Any]?,
                                       responseType: T.Type,
                                       isRetry: Bool = false) async throws -> T {
        try await withUnsafeThrowingContinuation { continuation in
            let headers = buildHeaders(headers)

            guard let url = buildRequestURL(path: path) else {
                continuation.resume(throwing: URLError(.badURL))
                return
            }

            AF.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
                .validate()
                .responseDecodable(of: responseType) { [weak self] response in
                    guard let self = self else { return }

                    switch response.result {
                    case .success(let value):
                        AppState.shared.needRelogin = false
                        continuation.resume(returning: value)
                    case .failure(let error):
                        if response.response?.statusCode == 401,
                           let refreshToken = self.refreshToken,
                           !isRetry {
                            // We need to refresh the token
                            Task {
                                do {
                                    try await self.refreshAccessToken(refreshToken)

                                    // Retry request
                                    let result = try await self.request(
                                        method: method,
                                        path: path,
                                        encoding: encoding,
                                        parameters: parameters,
                                        responseType: responseType,
                                        isRetry: true
                                    )
                                    continuation.resume(returning: result)
                                } catch {
                                    continuation.resume(throwing: error)
                                }
                            }
                            return
                        } else if response.response?.statusCode == 401 && path != "/identity/connect/token" {
                            // We have a 401 and no refresh token or already retried -> we need to login again
                            AppState.shared.needRelogin = true
                        }

                        // Other errors
                        if let data = response.data {
                            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                            if let errorResponse = errorResponse {
                                continuation.resume(throwing: errorResponse)
                                return
                            }
                        }
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
}
