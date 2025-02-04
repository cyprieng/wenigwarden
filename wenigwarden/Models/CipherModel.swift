//
//  Cipher.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 10/10/2024.
//

import SwiftUI
import Alamofire

/// Model representing a cipher
struct CipherModel: Codable, Identifiable {
    var id: String
    var type: CipherType
    var name: String
    var login: Login?
    var organizationId: String?
    var deletedDate: String?
    var key: String?
    var notes: String?
    var fields: [CustomFields]?
    var card: Card?
    var identity: Identity?
    var attachments: [Attachment]?

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
        case identity
        case type
        case attachments
    }

    /// Initializer for creating a new cipher model
    init(id: String,
         type: Int,
         name: String,
         login: Login?,
         organizationId: String?,
         deletedDate: String?,
         key: String?) {
        self.id = id
        self.type = CipherType(rawValue: type) ?? .login
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
        type = CipherType(rawValue: try container.decode(Int.self, forKey: .type)) ?? .login
        name = try container.decode(String.self, forKey: .name)
        login = try? container.decode(Login.self, forKey: .login)
        organizationId = try? container.decode(String.self, forKey: .organizationId)
        deletedDate = try? container.decode(String.self, forKey: .deletedDate)
        key = try? container.decode(String.self, forKey: .key)
        notes = try? container.decode(String.self, forKey: .notes)
        fields = try? container.decode([CustomFields].self, forKey: .fields)
        card = try? container.decode(Card.self, forKey: .card)
        identity = try? container.decode(Identity.self, forKey: .identity)
        attachments = try? container.decode([Attachment].self, forKey: .attachments)
    }

    /// Get decryption key for current cipher
    private func getDecKey() throws -> [UInt8]? {
        var decKey: [UInt8]?

        // Get the decryption key from organization keys if available
        if let orgId = organizationId {
            decKey = Vault.shared.orgsKey[orgId]
        }

        // Get the decryption key from the cipher's key if available
        if let key = self.key {
            decKey = try decrypt(str: key)
        }
        return decKey
    }

    /// Decrypt given string with given decryption key
    private func decryptString(_ input: String?, decKey: [UInt8]?) -> String? {
        if input != nil {
            if let decrypted = try? decrypt(decKey: decKey, str: input!) {
                return String(bytes: decrypted, encoding: .utf8)
            }
        }

        return nil
    }

    /// Decrypt identity
    func decryptIdentity(_ identity: Identity?, decKey: [UInt8]?) -> Identity {
        return Identity(
            address1: decryptString(identity?.address1, decKey: decKey),
            address2: decryptString(identity?.address2, decKey: decKey),
            address3: decryptString(identity?.address3, decKey: decKey),
            city: decryptString(identity?.city, decKey: decKey),
            company: decryptString(identity?.company, decKey: decKey),
            country: decryptString(identity?.country, decKey: decKey),
            email: decryptString(identity?.email, decKey: decKey),
            firstName: decryptString(identity?.firstName, decKey: decKey),
            lastName: decryptString(identity?.lastName, decKey: decKey),
            licenseNumber: decryptString(identity?.licenseNumber, decKey: decKey),
            middleName: decryptString(identity?.middleName, decKey: decKey),
            passportNumber: decryptString(identity?.passportNumber, decKey: decKey),
            phone: decryptString(identity?.phone, decKey: decKey),
            postalCode: decryptString(identity?.postalCode, decKey: decKey),
            ssn: decryptString(identity?.ssn, decKey: decKey),
            state: decryptString(identity?.state, decKey: decKey),
            title: decryptString(identity?.title, decKey: decKey),
            username: decryptString(identity?.username, decKey: decKey)
        )
    }

    /// Decrypts the cipher using the provided organization keys
    /// - Returns: Decrypted cipher model or nil if the cipher is deleted
    internal func decryptCipher() throws -> CipherModel? {
        // Return nil if the cipher is deleted
        if deletedDate != nil {
            return nil
        }

        // Create a new decrypted cipher model
        let decKey = try? getDecKey()
        var cipherDecoded = CipherModel(
            id: id,
            type: type.rawValue,
            name: decryptString(name, decKey: decKey)!,
            login: Login(
                username: decryptString(login?.username, decKey: decKey),
                password: decryptString(login?.password, decKey: decKey),
                totp: decryptString(login?.totp, decKey: decKey),
                uri: decryptString(login?.uri, decKey: decKey),
                uris: []
            ),
            organizationId: organizationId,
            deletedDate: nil,
            key: key
        )

        // Decrypt the URIs if available
        for uri in login?.uris ?? [] {
            if let decryptedUri = decryptString(uri.uri, decKey: decKey) {
                cipherDecoded.login?.uris?.append(Uris(uri: decryptedUri))
            }
        }

        // Notes
        cipherDecoded.notes = decryptString(notes, decKey: decKey)

        // Custom fields
        cipherDecoded.fields = []
        for field in fields ?? [] {
            cipherDecoded.fields?.append(CustomFields(name: decryptString(field.name, decKey: decKey) ?? "",
                                                      value: decryptString(field.value ?? "", decKey: decKey) ?? "",
                                                      type: field.type))
        }

        // Card details
        cipherDecoded.card = Card(
            cardholderName: decryptString(card?.cardholderName, decKey: decKey),
            code: decryptString(card?.code, decKey: decKey),
            expMonth: decryptString(card?.expMonth, decKey: decKey),
            expYear: decryptString(card?.expYear, decKey: decKey),
            number: decryptString(card?.number, decKey: decKey)
        )

        // Identity
        cipherDecoded.identity = decryptIdentity(identity, decKey: decKey)

        // Attachments
        cipherDecoded.attachments = []
        for attachment in attachments ?? [] {
            cipherDecoded.attachments?.append(
                Attachment(id: attachment.id,
                           fileName: decryptString(attachment.fileName, decKey: decKey))
            )
        }

        return cipherDecoded
    }

    /// Retrieves the favicon for the cipher's URI
    /// - Returns: The favicon image or nil if not available
    internal func getFavicon() async -> Image? {
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

    /// Download attachment
    internal func downloadAttachment(_ attachmentId: String) async {
        let data = try? await BitwardenAPI.shared.getAttachmentData(cipherId: id, attachmentId: attachmentId)
        if let urlString = data?.url, !urlString.isEmpty {
            guard let url = URL(string: urlString) else { return }

            // Get attachment
            let attachment = attachments?.filter { $0.id == attachmentId }.first
            guard let filename = attachment?.fileName else { return }

            // Get attachment decryption key
            let decKey = try? getDecKey()
            let decryptKey = try? decrypt(decKey: decKey, str: data!.key)

            // Show native save dialog
            DispatchQueue.main.async {
                let savePanel = NSSavePanel()
                savePanel.nameFieldStringValue = filename
                savePanel.canCreateDirectories = true
                savePanel.allowedContentTypes = [.data]

                let response = savePanel.runModal()
                if response == .OK, let destinationURL = savePanel.url {
                    AF.request(url)
                        .responseData { response in
                            switch response.result {
                            case .success(let encryptedData):
                                do {
                                    let decryptedBytes = try decryptData(key: decryptKey!, data: encryptedData)
                                    let decryptedData = Data(decryptedBytes)
                                    try decryptedData.write(to: destinationURL)
                                } catch {
                                    print("Error decrypting: \(error)")
                                }
                            case .failure(let error):
                                print("Error downloading: \(error)")
                            }
                        }
                }
            }
        }
    }
}
