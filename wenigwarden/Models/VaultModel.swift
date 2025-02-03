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
        uri = try? container.decode(String.self, forKey: .uri)
        uris = try? container.decode([Uris].self, forKey: .uris)
    }
}

/// Model representing a URI
struct Uris: Codable, Identifiable {
    var uri: String

    var id: String { uri }

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

    /// Initializer for decoding a profile model
    init(from decoder: Decoder) throws {
        let caseInsensitiveDecoder = CaseInsensitiveDecoder(decoder)
        let container = try caseInsensitiveDecoder.container(keyedBy: CodingKeys.self)
        organizations = try container.decode([Organization].self, forKey: .organizations)
    }
}

/// Model representing an organization
struct Organization: Codable {
    // periphery:ignore
    let id: String
    let key: String

    /// Coding keys for encoding and decoding
    enum CodingKeys: String, CodingKey {
        case id
        case key
    }

    /// Initializer for decoding an organization model
    init(from decoder: Decoder) throws {
        let caseInsensitiveDecoder = CaseInsensitiveDecoder(decoder)
        let container = try caseInsensitiveDecoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        key = try container.decode(String.self, forKey: .key)
    }
}

/// Model representing custom fields
struct CustomFields: Codable, Identifiable {
    let name: String
    let value: String?
    let type: Int

    var id: String { name }

    /// Coding keys for encoding and decoding
    enum CodingKeys: String, CodingKey {
        case name
        case value
        case type
    }

    /// Initializer for creating a new organization model
    init(name: String, value: String, type: Int) {
        self.name = name
        self.value = value
        self.type = type
    }

    /// Initializer for decoding an organization model
    init(from decoder: Decoder) throws {
        let caseInsensitiveDecoder = CaseInsensitiveDecoder(decoder)
        let container = try caseInsensitiveDecoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        value = try? container.decode(String.self, forKey: .value)
        type = try container.decode(Int.self, forKey: .type)
    }
}

/// Model representing a payment card
struct Card: Codable {
    var cardholderName: String?
    var code: String?
    var expMonth: String?
    var expYear: String?
    var number: String?

    /// Coding keys for encoding and decoding
    enum CodingKeys: String, CodingKey {
        case cardholderName
        case code
        case expMonth
        case expYear
        case number
    }

    /// Initializer for creating a new payment card model
    init(cardholderName: String? = nil,
         code: String? = nil,
         expMonth: String? = nil,
         expYear: String? = nil,
         number: String? = nil) {
        self.cardholderName = cardholderName
        self.code = code
        self.expMonth = expMonth
        self.expYear = expYear
        self.number = number
    }

    /// Initializer for decoding a payment card model
    init(from decoder: Decoder) throws {
        let caseInsensitiveDecoder = CaseInsensitiveDecoder(decoder)
        let container = try caseInsensitiveDecoder.container(keyedBy: CodingKeys.self)
        cardholderName = try? container.decode(String.self, forKey: .cardholderName)
        code = try? container.decode(String.self, forKey: .code)
        expMonth = try? container.decode(String.self, forKey: .expMonth)
        expYear = try? container.decode(String.self, forKey: .expYear)
        number = try? container.decode(String.self, forKey: .number)
    }
}

/// Model representing an identity
struct Identity: Codable {
    var address1: String?
    var address2: String?
    var address3: String?
    var city: String?
    var company: String?
    var country: String?
    var email: String?
    var firstName: String?
    var lastName: String?
    var licenseNumber: String?
    var middleName: String?
    var passportNumber: String?
    var phone: String?
    var postalCode: String?
    var ssn: String?
    var state: String?
    var title: String?
    var username: String?

    /// Coding keys for encoding and decoding
    enum CodingKeys: String, CodingKey {
        case address1
        case address2
        case address3
        case city
        case company
        case country
        case email
        case firstName
        case lastName
        case licenseNumber
        case middleName
        case passportNumber
        case phone
        case postalCode
        case ssn
        case state
        case title
        case username
    }

    /// Initializer for creating a new identity model
    init(address1: String? = nil,
         address2: String? = nil,
         address3: String? = nil,
         city: String? = nil,
         company: String? = nil,
         country: String? = nil,
         email: String? = nil,
         firstName: String? = nil,
         lastName: String? = nil,
         licenseNumber: String? = nil,
         middleName: String? = nil,
         passportNumber: String? = nil,
         phone: String? = nil,
         postalCode: String? = nil,
         ssn: String? = nil,
         state: String? = nil,
         title: String? = nil,
         username: String? = nil) {
        self.address1 = address1
        self.address2 = address2
        self.address3 = address3
        self.city = city
        self.company = company
        self.country = country
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.licenseNumber = licenseNumber
        self.middleName = middleName
        self.passportNumber = passportNumber
        self.phone = phone
        self.postalCode = postalCode
        self.ssn = ssn
        self.state = state
        self.title = title
        self.username = username
    }

    /// Initializer for decoding an identity model
    init(from decoder: Decoder) throws {
        let caseInsensitiveDecoder = CaseInsensitiveDecoder(decoder)
        let container = try caseInsensitiveDecoder.container(keyedBy: CodingKeys.self)
        address1 = try? container.decode(String.self, forKey: .address1)
        address2 = try? container.decode(String.self, forKey: .address2)
        address3 = try? container.decode(String.self, forKey: .address3)
        city = try? container.decode(String.self, forKey: .city)
        company = try? container.decode(String.self, forKey: .company)
        country = try? container.decode(String.self, forKey: .country)
        email = try? container.decode(String.self, forKey: .email)
        firstName = try? container.decode(String.self, forKey: .firstName)
        lastName = try? container.decode(String.self, forKey: .lastName)
        licenseNumber = try? container.decode(String.self, forKey: .licenseNumber)
        middleName = try? container.decode(String.self, forKey: .middleName)
        passportNumber = try? container.decode(String.self, forKey: .passportNumber)
        phone = try? container.decode(String.self, forKey: .phone)
        postalCode = try? container.decode(String.self, forKey: .postalCode)
        ssn = try? container.decode(String.self, forKey: .ssn)
        state = try? container.decode(String.self, forKey: .state)
        title = try? container.decode(String.self, forKey: .title)
        username = try? container.decode(String.self, forKey: .username)
    }
}

/// Model representing an attachment
struct Attachment: Codable, Identifiable {
    var id: String?
    var fileName: String?

    /// Coding keys for encoding and decoding
    enum CodingKeys: String, CodingKey {
        case id
        case fileName
    }

    /// Initializer for creating a new attachment model
    init(id: String? = nil,
         fileName: String? = nil) {
        self.id = id
        self.fileName = fileName
    }

    /// Initializer for decoding an attachment model
    init(from decoder: Decoder) throws {
        let caseInsensitiveDecoder = CaseInsensitiveDecoder(decoder)
        let container = try caseInsensitiveDecoder.container(keyedBy: CodingKeys.self)
        id = try? container.decode(String.self, forKey: .id)
        fileName = try? container.decode(String.self, forKey: .fileName)
    }
}
