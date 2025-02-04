//
//  VaultService.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 22/08/2024.
//

import Foundation
import KeychainAccess

/// Vault errors enum
enum VaultError: Error {
    case invalidMasterKey
}

/// The `Vault` class manages the user's vault of ciphers and profile information.
class Vault: ObservableObject {
    // Singleton instance of Vault
    static let shared = Vault()

    // Published property to notify observers when the vault is unlocked
    @Published var unlocked: Bool = false

    // Indicates if the user is logged in
    private(set) var logged: Bool = false

    // Keychain instance for storing sensitive data
    private var keychain: Keychain

    // Arrays to store ciphers and decrypted ciphers
    private var ciphers: [CipherModel]
    private(set) var ciphersDecrypted: [CipherModel]

    // User profile
    private var profile: Profile?

    // Encrypted keys
    private var encryptedPrivateKey: String?
    private var encryptedEncKey: String?

    // Key derivation function iterations
    private var kdfIterations: Int?

    // Keys
    private var masterKey: Data?
    private var privateKey: SecKey?
    private(set) var encKey: [UInt8]?
    private(set) var orgsKey: [String: [UInt8]] = [:]

    /// Private initializer to enforce singleton pattern
    private init() {
        ciphers = []
        ciphersDecrypted = []

        keychain = Keychain(service: "io.cyprien.wenigwarden")
        self.loadFromKeychain()
    }

    /// Set password in keychain for touchid
    internal func setTouchIdPassword(_ password: String) {
        // Always remove first as override cause issue
        try? keychain.remove("touchidpassword")

        DispatchQueue.global().async {
            do {
                // Store in keychain
                try self.keychain
                    .accessibility(.whenUnlocked, authenticationPolicy: [.biometryAny])
                    .authenticationPrompt("Authenticate to update your password")
                    .set(password, key: "touchidpassword")
            } catch {}
        }
    }

    /// Get password from touchid keychain
    internal func getTouchIdPassword() -> String? {
        return try? Vault.shared.keychain
            .authenticationPrompt("Authenticate to get your password")
            .get("touchidpassword") as String?
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
    ///   - password: The user's password
    ///   - otp: OTP if needed
    internal func login(email: String, password: String, otp: String? = nil) async throws {
        // Perform prelogin to get KDF iterations
        let preloginResponse = try await BitwardenAPI.shared.prelogin(email: email)

        // Login with email, password, and KDF iterations
        let loginResp = try await BitwardenAPI.shared.login(email: email,
                                                            password: password,
                                                            kdfIterations: preloginResponse.kdfIterations,
                                                            otp: otp)

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
    internal func sync() async throws {
        let vault = try await BitwardenAPI.shared.sync()
        ciphers = vault.ciphers
        profile = vault.profile

        // Get ciphers and profile as Data
        let encoder = JSONEncoder()
        let ciphersJSON = try encoder.encode(ciphers)
        let profileJSON = try encoder.encode(profile)

        keychain[data: "ciphers"] = ciphersJSON
        keychain[data: "profile"] = profileJSON

        // Save sync date
        AppState.shared.lastVaultSync = Date()
        AppState.shared.persist()
    }

    /// Update the vaule by syncing and unlocking it
    internal func updateVault() async throws {
        // Synchronize the vault
        try await sync()

        // Unlock the vault with the master key
        try await unlock()
    }

    /// Sets the encrypted keys and KDF iterations
    /// - Parameters:
    ///   - encryptedEncKey: The encrypted encryption key
    ///   - encryptedPrivateKey: The encrypted private key
    ///   - kdfIterations: The number of key derivation function iterations
    internal func setKeys(encryptedEncKey: String, encryptedPrivateKey: String, kdfIterations: Int) {
        self.encryptedEncKey = encryptedEncKey
        self.encryptedPrivateKey = encryptedPrivateKey
        self.kdfIterations = kdfIterations

        // Store them in keychain
        keychain["encryptedEncKey"] = encryptedEncKey
        keychain["encryptedPrivateKey"] = encryptedPrivateKey
        keychain["kdfIterations"] = String(kdfIterations)

        self.logged = true
    }

    /// Unlocks the vault using the current encryption key
    internal func unlock() async throws {
        return try await self.unlock(masterKey: self.masterKey!)
    }

    /// Unlocks the vault using the user's password
    /// - Parameter password: The user's password
    internal func unlock(password: String) async throws {
        let appState = AppState.shared
        let masterKey = generateMasterKey(email: appState.email, password: password, kdfIterations: self.kdfIterations!)
        return try await self.unlock(masterKey: masterKey!)
    }

    /// Unlocks the vault using the master key
    /// - Parameter masterKey: The master key
    internal func unlock(masterKey: Data) async throws {
        self.masterKey = masterKey
        self.encKey = try decrypt(encKey: [UInt8](masterKey), str: encryptedEncKey!)

        // Enc key empty -> master key is invalid
        if encKey?.isEmpty ?? true {
            throw VaultError.invalidMasterKey
        }

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
            if let cipherDecoded = try cipher.decryptCipher() {
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

    /// Set unlogged without resetting any data
    public func setUnlogged() {
        self.logged = false
        self.unlocked = false
    }

    /// Locks the vault, clearing decrypted data
    internal func lock() {
        unlocked = false
        ciphersDecrypted = []
        masterKey = nil
        privateKey = nil
        encKey = nil
        orgsKey = [:]
    }

    /// Reset vault
    internal func reset() {
        try? keychain.remove("touchidpassword")
        try? keychain.remove("ciphers")
        try? keychain.remove("profile")
        try? keychain.remove("encryptedEncKey")
        try? keychain.remove("encryptedPrivateKey")
        try? keychain.remove("kdfIterations")

        self.ciphers = []
        self.profile = nil
        self.encryptedPrivateKey = nil
        self.encryptedEncKey = nil
        self.kdfIterations = nil

        self.lock()

        self.logged = false
    }

    /// Searches for ciphers matching the query
    /// - Parameter query: The search query
    /// - Returns: An array of ciphers matching the query
    internal func search(query: String) -> [CipherModel] {
        return ciphersDecrypted.filter {
            $0.name.lowercased().contains(query.lowercased()) ||
                ($0.login?.username ?? "").lowercased().contains(query.lowercased()) ||
                ($0.login?.uri ?? "").lowercased().contains(query.lowercased())
        }
    }
}
