//
//  Cipher.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 10/10/2024.
//

import SwiftUI

/// Model representing a cipher
struct CipherModel: Codable, Identifiable {
    var id: String
    var name: String
    var login: Login?
    var organizationId: String?
    var deletedDate: String?
    var key: String?
    var image: Image?
    var notes: String?
    var fields: [CustomFields]?
    var card: Card?

    /// Coding keys for encoding and decoding
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case login
        case organizationId
        case deletedDate
        case key
        case notes
        case fields
        case card
    }

    /// Initializer for creating a new cipher model
    init(id: String, name: String, login: Login?, organizationId: String?, deletedDate: String?, key: String?) {
        self.id = id
        self.name = name
        self.login = login
        self.organizationId = organizationId
        self.deletedDate = deletedDate
        self.key = key
    }

    /// Initializer for decoding a cipher model
    init(from decoder: Decoder) throws {
        let caseInsensitiveDecoder = CaseInsensitiveDecoder(decoder)
        let container = try caseInsensitiveDecoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        login = try? container.decode(Login.self, forKey: .login)
        organizationId = try? container.decode(String.self, forKey: .organizationId)
        deletedDate = try? container.decode(String.self, forKey: .deletedDate)
        key = try? container.decode(String.self, forKey: .key)
        notes = try? container.decode(String.self, forKey: .notes)
        fields = try? container.decode([CustomFields].self, forKey: .fields)
        card = try? container.decode(Card.self, forKey: .card)
    }

    private func decryptString(_ input: String?, decKey: [UInt8]?) -> String? {
        if input != nil {
            if let decrypted = try? decrypt(decKey: decKey, str: input!) {
                return String(bytes: decrypted, encoding: .utf8)
            }
        }

        return nil
    }

    /// Decrypts the cipher using the provided organization keys
    /// - Parameter orgsKey: Dictionary of organization keys
    /// - Returns: Decrypted cipher model or nil if the cipher is deleted
    public func decryptCipher(orgsKey: [String: [UInt8]] = [:]) throws -> CipherModel? {
        // Return nil if the cipher is deleted
        if deletedDate != nil {
            return nil
        }

        // Create a new decrypted cipher model
        var cipherDecoded = CipherModel(
            id: id, name: "",
            login: Login(username: nil, password: nil, totp: nil, uri: nil, uris: nil),
            organizationId: organizationId, deletedDate: nil, key: nil)

        var decKey: [UInt8]?
        // Get the decryption key from organization keys if available
        if let orgId = organizationId {
            decKey = orgsKey[orgId]
        }
        // Get the decryption key from the cipher's key if available
        if let key = self.key {
            decKey = try decrypt(str: key)
        }

        // Decrypt the name of the cipher
        let name = try decrypt(decKey: decKey, str: name)
        cipherDecoded.name = String(bytes: name, encoding: .utf8)!

        // Decrypt the username if available
        if let username = login?.username {
            let decryptedUsername = try decrypt(decKey: decKey, str: username)
            cipherDecoded.login?.username = String(bytes: decryptedUsername, encoding: .utf8)
        }

        // Decrypt the password if available
        if let password = login?.password {
            let decryptedPassword = try decrypt(decKey: decKey, str: password)
            cipherDecoded.login?.password = String(bytes: decryptedPassword, encoding: .utf8)
        }

        // Decrypt the URI if available
        if let uri = login?.uri {
            let decryptedUri = try decrypt(decKey: decKey, str: uri)
            cipherDecoded.login?.uri = String(bytes: decryptedUri, encoding: .utf8)
        }

        // Decrypt the URIs if available
        var urisDecoded: [Uris] = []
        if let uris = login?.uris {
            for uri in uris {
                let decryptedUri = try decrypt(decKey: decKey, str: uri.uri)
                urisDecoded.append(Uris(uri: String(bytes: decryptedUri, encoding: .utf8)!))
            }
        }
        cipherDecoded.login?.uris = urisDecoded

        // Notes
        if notes != nil {
            let decryptedNote = try decrypt(decKey: decKey, str: notes!)
            cipherDecoded.notes = String(bytes: decryptedNote, encoding: .utf8)
        }

        // Custom fields
        var decodedFields: [CustomFields] = []
        if let fields = fields {
            for field in fields {
                let decryptedName = try decrypt(decKey: decKey, str: field.name)
                let decryptedValue = try decrypt(decKey: decKey, str: field.value ?? "")
                decodedFields.append(CustomFields(name: String(bytes: decryptedName, encoding: .utf8)!,
                                                  value: String(bytes: decryptedValue, encoding: .utf8)!,
                                                  type: field.type))
            }
        }
        cipherDecoded.fields = decodedFields

        // Totp
        if let totp = login?.totp {
            let decryptedTotp = try decrypt(decKey: decKey, str: totp)
            cipherDecoded.login!.totp = String(bytes: decryptedTotp, encoding: .utf8)
        }

        // Card details
        cipherDecoded.card = Card(
            cardholderName: decryptString(card?.cardholderName, decKey: decKey),
            code: decryptString(card?.code, decKey: decKey),
            expMonth: decryptString(card?.expMonth, decKey: decKey),
            expYear: decryptString(card?.expYear, decKey: decKey),
            number: decryptString(card?.number, decKey: decKey)
        )

        return cipherDecoded
    }

    /// Retrieves the favicon for the cipher's URI
    /// - Returns: The favicon image or nil if not available
    public func getFavicon() async -> Image? {
        guard let uriString = login?.uri,
              let url = URL(string: uriString),
              let hostname = url.host,
              let faviconUrl = URL(string: "\(AppState.shared.url)/icons/\(hostname)/icon.png") else {
            return nil
        }

        // Configure URL session with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10 // 10 seconds timeout
        let session = URLSession(configuration: config)

        do {
            let (data, response) = try await session.data(from: faviconUrl)

            // Check for valid response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Invalid response for favicon: \(hostname)")
                return nil
            }

            // Create and return the image
            if let nsImage = NSImage(data: data) {
                return SwiftUI.Image(nsImage: nsImage)
            }
        } catch {
            print("Error loading favicon for \(hostname): \(error)")
        }

        return nil
    }
}
