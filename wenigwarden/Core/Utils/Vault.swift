//
//  VaultService.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 22/08/2024.
//

import Foundation
import KeychainAccess

/// The `Vault` class manages the user's vault of ciphers and profile information.
class Vault: ObservableObject {
    // Singleton instance of Vault
    static let shared = Vault()

    // Published property to notify observers when the vault is unlocked
    @Published var unlocked: Bool = false

    // Indicates if the user is logged in
    var logged: Bool = false

    // Keychain instance for storing sensitive data
    var keychain: Keychain

    // Arrays to store ciphers and decrypted ciphers
    var ciphers: [CipherModel]
    var ciphersDecrypted: [CipherModel]

    // User profile
    var profile: Profile?

    // Encrypted keys
    var encryptedPrivateKey: String?
    var encryptedEncKey: String?

    // Key derivation function iterations
    var kdfIterations: Int?

    // Keys
    var masterKey: Data?
    var privateKey: SecKey?
    var encKey: [UInt8]?
    var orgsKey: [String: [UInt8]] = [:]

    /// Private initializer to enforce singleton pattern
    private init() {
        ciphers = []
        ciphersDecrypted = []

        keychain = Keychain(service: "io.cyprien.wenigwarden")
        self.loadFromKeychain()
    }

    /// Loads data from the keychain
    private func loadFromKeychain() {
        let ciphers = try? keychain.getData("ciphers")
        let profile = try? keychain.getData("profile")

        if let ciphers, let profile {
            do {
                self.ciphers = try JSONDecoder().decode([CipherModel].self, from: ciphers)
                self.profile = try JSONDecoder().decode(Profile.self, from: profile)
            } catch let error {
                print(error)
            }
        }

        encryptedEncKey = try? keychain.get("encryptedEncKey")
        encryptedPrivateKey = try? keychain.get("encryptedPrivateKey")
        if let kdfIterationsString = try? keychain.get("kdfIterations") {
            kdfIterations = Int(kdfIterationsString)
        }

        if ciphers != nil, profile != nil, encryptedEncKey != nil, encryptedPrivateKey != nil, kdfIterations != nil {
            DispatchQueue.main.async {
                self.logged = true
            }
        }
    }

    /// Logs in the user with the given credentials
    /// - Parameters:
    ///   - email: The user's email address
    ///   - url: The Bitwarden service URL
    ///   - password: The user's password
    public func login(email: String, url: String, password: String) async throws {
        // Set Bitwarden service URL
        let bitwardenService = BitwardenAPI.shared
        bitwardenService.host = url

        // Perform prelogin to get KDF iterations
        let preloginResponse = try await bitwardenService.prelogin(email: email)

        // Login with email, password, and KDF iterations
        let loginResp = try await bitwardenService.login(email: email,
                                                         password: password,
                                                         kdfIterations: preloginResponse.kdfIterations)

        // Set encrypted keys and KDF iterations
        setKeys(encryptedEncKey: loginResp.key,
                encryptedPrivateKey: loginResp.privateKey,
                kdfIterations: preloginResponse.kdfIterations)

        // Synchronize the vault
        try await sync()

        // Unlock the vault with the master key
        try await unlock(masterKey: loginResp.masterKey!)
    }

    /// Synchronizes the vault with the server
    public func sync() async throws {
        let vault = try await BitwardenAPI.shared.sync()
        ciphers = vault.ciphers
        profile = vault.profile

        // Get ciphers and profile as Data
        let encoder = JSONEncoder()
        let ciphersJSON = try encoder.encode(ciphers)
        let profileJSON = try encoder.encode(profile)

        keychain[data: "ciphers"] = ciphersJSON
        keychain[data: "profile"] = profileJSON
    }

    /// Sets the encrypted keys and KDF iterations
    /// - Parameters:
    ///   - encryptedEncKey: The encrypted encryption key
    ///   - encryptedPrivateKey: The encrypted private key
    ///   - kdfIterations: The number of key derivation function iterations
    public func setKeys(encryptedEncKey: String, encryptedPrivateKey: String, kdfIterations: Int) {
        self.encryptedEncKey = encryptedEncKey
        self.encryptedPrivateKey = encryptedPrivateKey
        self.kdfIterations = kdfIterations

        // Store them in keychain
        keychain["encryptedEncKey"] = encryptedEncKey
        keychain["encryptedPrivateKey"] = encryptedPrivateKey
        keychain["kdfIterations"] = String(kdfIterations)

        self.logged = true
    }

    /// Unlocks the vault using the user's password
    /// - Parameter password: The user's password
    public func unlock(password: String) async throws {
        let appState = AppState.shared
        let masterKey = generateMasterKey(email: appState.email, password: password, kdfIterations: self.kdfIterations!)
        return try await self.unlock(masterKey: masterKey!)
    }

    /// Unlocks the vault using the master key
    /// - Parameter masterKey: The master key
    public func unlock(masterKey: Data) async throws {
        self.encKey = try decrypt(encKey: [UInt8](masterKey), str: encryptedEncKey!)
        let tempPrivateKey = try decrypt(str: encryptedPrivateKey!).toBase64()

        // Turn the private key into PEM formatted key
        privateKey = SecKeyCreateWithData(
            try pemToPKCS1DER(tempPrivateKey)! as CFData,
            [kSecAttrKeyType: kSecAttrKeyTypeRSA, kSecAttrKeyClass: kSecAttrKeyClassPrivate]
                as CFDictionary, nil)

        // Get organization keys
        for org in profile?.organizations ?? [] {
            let orgKey = String(org.key.split(separator: ".")[1])
            let decrypted =
                SecKeyCreateDecryptedData(
                    privateKey!, .rsaEncryptionOAEPSHA1, Data(base64Encoded: orgKey)! as CFData, nil
                ) as? Data
            let smKey = decrypted!.bytes
            orgsKey[org.id] = smKey
        }
        var newCiphersDecrypted = [CipherModel]()

        for cipher in ciphers {
            if let cipherDecoded = try cipher.decryptCipher(orgsKey: orgsKey) {
                newCiphersDecrypted.append(cipherDecoded)
            }
        }

        // Sort ciphers by name
        newCiphersDecrypted.sort { $0.name.lowercased() < $1.name.lowercased() }
        ciphersDecrypted = newCiphersDecrypted

        if !self.unlocked {
            await MainActor.run {
                self.unlocked = true
            }
        }
    }

    /// Locks the vault, clearing decrypted data
    public func lock() {
        ciphersDecrypted = []
        privateKey = nil
        encKey = nil
        orgsKey = [:]
    }

    /// Searches for ciphers matching the query
    /// - Parameter query: The search query
    /// - Returns: An array of ciphers matching the query
    public func search(query: String) -> [CipherModel] {
        return ciphersDecrypted.filter { $0.name.lowercased().contains(query.lowercased()) }
    }
}
