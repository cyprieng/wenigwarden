import Foundation
import CommonCrypto
import CryptoSwift

// swiftlint:disable identifier_name

/// Generates a master encryption key using email and password
/// - Parameters:
///   - email: User's email address used as salt
///   - password: User's password
///   - kdfIterations: Number of iterations for key derivation
/// - Returns: Derived key as Data object or nil if generation fails
func generateMasterKey(email: String, password: String, kdfIterations: Int) -> Data? {
    return pbkdf2(hash: CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256),
                  passwordData: password.data(using: .utf8)!,
                  salt: email.lowercased().data(using: .utf8)!,
                  keyByteCount: 256/8,
                  rounds: kdfIterations)
}

/// Securely compares two MAC (Message Authentication Code) values
/// - Parameters:
///   - macKey: Key used for HMAC calculation
///   - mac1: First MAC value to compare
///   - mac2: Second MAC value to compare
/// - Returns: Boolean indicating if MACs are equal
func macsEqual(macKey: [UInt8], mac1: [UInt8], mac2: [UInt8]) -> Bool {
    do {
        let hmac1 = try HMAC(key: macKey, variant: .sha2(.sha256)).authenticate(mac1)
        let hmac2 = try HMAC(key: macKey, variant: .sha2(.sha256)).authenticate(mac2)
        return hmac1 == hmac2
    } catch {return false}
}

/// Implements HKDF (HMAC-based Key Derivation Function) to stretch a key
/// - Parameters:
///   - prk: Input key material
///   - info: Context and application specific information
///   - size: Desired output size in bytes
/// - Returns: Derived key material
func hkdfStretch(prk: [UInt8], info: String, size: Int) -> [UInt8] {
    let hashlen = 32
    var prev: [UInt8] = []
    var okm: [UInt8] = []
    let n: Int = Int(ceil(Double((size / hashlen))))
    let inf = Data(info.utf8)
    for i in 0..<n {
        var t: [UInt8] = []
        t += prev
        t += inf
        t += [UInt8(i+1)]
        do {
            let hmac = try HMAC(key: prk, variant: .sha2(.sha256)).authenticate(t)
            okm += hmac
            prev = hmac
        } catch {}

        if okm.count != size {
            print("Error")
        }
    }
    return okm
}

/// Convenience function to decrypt string using vault's encryption key
/// - Parameter str: Encrypted string to decrypt
/// - Returns: Decrypted bytes
func decrypt(str: String) throws -> [UInt8] {
    return try decrypt(key: Vault.shared.encKey!, str: str)
}

/// Decrypts an encrypted string using provided key or vault's encryption key
/// - Parameters:
///   - key: Encryption key to use (optional)
///   - str: Encrypted string to decrypt
/// - Returns: Decrypted bytes
func decrypt(key: [UInt8]?, str: String) throws -> [UInt8] {
    var macKey: [UInt8] = []
    var decryptKey: [UInt8] = key ?? Vault.shared.encKey!

    // Break the encrypted string into it's iv and data components
    let split = str.components(separatedBy: "|")
    if split.count == 1 {
        return []
    }

    let iv = (Data(base64Encoded: String(split[0].dropFirst(2)))?.bytes)
    let ct = (Data(base64Encoded: split[1])?.bytes)
    let mac2 = (Data(base64Encoded: split[2])?.bytes)
    if split[0].prefix(1) == "2" {
        if decryptKey.count == 32 {
            macKey = hkdfStretch(prk: decryptKey, info: "mac", size: 32)
            decryptKey = hkdfStretch(prk: decryptKey, info: "enc", size: 32)
        } else if decryptKey.count == 64 {
            macKey = Array(decryptKey.suffix(32))
            decryptKey = Array(decryptKey.prefix(32))
        }
    }
    do {
        let mac1 = try HMAC(key: macKey, variant: .sha2(.sha256)).authenticate((iv ?? []) + (ct ?? []))
        if !macsEqual(macKey: macKey, mac1: mac1, mac2: mac2 ?? []) {
            return []
        }

        let aes = try AES(key: decryptKey, blockMode: CBC(iv: iv ?? []))
        let pt = try aes.decrypt(ct ?? [])

        return pt
    } catch {
        print("Error decrypting: \(error).")
        return []
    }
}

/// Decrypts data using AES-CBC with provided key
/// - Parameters:
///   - key: Encryption key
///   - data: Encrypted data
/// - Returns: Decrypted data
func decryptData(key: [UInt8], data: Data) throws -> Data {
    // Key are the 32 first bytes
    let key = Array(key.prefix(32))

    // Split data
    let iv = data[1..<17]
    let ct =  data[49...]

    // Decrypt
    let aes = try AES(key: key, blockMode: CBC(iv: Array(iv)), padding: .pkcs7)
    let pt = try aes.decrypt(Array(ct))

    return Data(pt)
}

/// Performs PBKDF2 key derivation
/// - Parameters:
///   - hash: Hash algorithm to use
///   - passwordData: Password data
///   - salt: Salt data
///   - keyByteCount: Desired key length in bytes
///   - rounds: Number of iterations
/// - Returns: Derived key as Data object
func pbkdf2(hash: CCPBKDFAlgorithm, passwordData: Data, salt: Data, keyByteCount: Int, rounds: Int) -> Data? {
    let passwordBytes = passwordData.withUnsafeBytes { (passwordPtr: UnsafeRawBufferPointer) -> UnsafePointer<Int8> in
        return passwordPtr.bindMemory(to: Int8.self).baseAddress!
    }

    let derivedKeyData = Data(repeating: 0, count: keyByteCount)

    var derivedKeyDataPointer = derivedKeyData
    let derivationStatus = derivedKeyDataPointer.withUnsafeMutableBytes { derivedKeyBytes -> Int32 in
        salt.withUnsafeBytes { saltBytes -> Int32 in
            CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                passwordBytes, passwordData.count,
                saltBytes.baseAddress, salt.count,
                hash,
                UInt32(rounds),
                derivedKeyBytes.baseAddress, derivedKeyData.count)
        }
    }
    if derivationStatus != 0 {
        print("Error: \(derivationStatus)")
        return nil
    }

    return derivedKeyDataPointer
}

/// Converts PEM format private key to PKCS1 DER format
/// - Parameter pemKey: Private key in PEM format
/// - Returns: Private key in DER format
func pemToPKCS1DER(_ pemKey: String) throws -> Data? {
    guard let derKey = try? PEM.PrivateKey.toDER(pemKey) else {
        return nil
    }
    guard let pkcs1DERKey = PKCS8.PrivateKey.stripHeaderIfAny(derKey) else {
        return nil
    }
    return pkcs1DERKey
}

/// PKCS8 key format handling class
class PKCS8 {
    class PrivateKey {
        // swiftlint:disable cyclomatic_complexity
        /// Gets the offset of PKCS1 data in DER format key
        /// - Parameter derKey: Key in DER format
        /// - Returns: Offset to PKCS1 data or nil if invalid
        public static func getPKCS1DEROffset(_ derKey: Data) -> Int? {
            let bytes = derKey.bytesView

            var offset = 0
            guard bytes.length > offset else { return nil }
            guard bytes[offset] == 0x30 else { return nil }

            offset += 1

            guard bytes.length > offset else { return nil }
            if bytes[offset] > 0x80 {
                offset += Int(bytes[offset]) - 0x80
            }
            offset += 1

            guard bytes.length > offset else { return nil }
            guard bytes[offset] == 0x02 else { return nil }

            offset += 3

            // without PKCS8 header
            guard bytes.length > offset else { return nil }
            if bytes[offset] == 0x02 {
                return 0
            }

            let OID: [UInt8] = [0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
                                0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00]

            guard bytes.length > offset + OID.count else { return nil }
            let slice = derKey.bytesViewRange(NSRange(location: offset, length: OID.count))

            guard OID.elementsEqual(slice) else { return nil }

            offset += OID.count

            guard bytes.length > offset else { return nil }
            guard bytes[offset] == 0x04 else { return nil }

            offset += 1

            guard bytes.length > offset else { return nil }
            if bytes[offset] > 0x80 {
                offset += Int(bytes[offset]) - 0x80
            }
            offset += 1

            guard bytes.length > offset else { return nil }
            guard bytes[offset] == 0x30 else { return nil }

            return offset
        }

        /// Strips PKCS8 header from DER format key if present
        /// - Parameter derKey: Key in DER format
        /// - Returns: Key with header stripped or nil if invalid
        public static func stripHeaderIfAny(_ derKey: Data) -> Data? {
            guard let offset = getPKCS1DEROffset(derKey) else {
                return nil
            }
            return derKey.subdata(in: offset..<derKey.count)
        }
    }
}

/// PEM format handling class
class PEM {
    class PrivateKey {
        /// Converts PEM format key to DER format
        /// - Parameter pemKey: Key in PEM format
        /// - Returns: Key in DER format
        public static func toDER(_ pemKey: String) throws -> Data? {
            guard let data = PEM.base64Decode(pemKey) else {
                return nil
            }
            return data
        }
    }

    /// Decodes base64 string to Data
    fileprivate static func base64Decode(_ base64Data: String) -> Data? {
        return Data(base64Encoded: base64Data, options: [.ignoreUnknownCharacters])
    }
}

/// Data extension for byte manipulation
extension Data {
    fileprivate var bytesView: BytesView { return BytesView(self) }

    fileprivate func bytesViewRange(_ range: NSRange) -> BytesView {
        return BytesView(self, range: range)
    }

    /// BytesView struct for efficient byte access
    fileprivate struct BytesView: Collection {
        let data: Data
        init(_ data: Data) {
            self.data = data
            self.startIndex = 0
            self.endIndex = data.count
        }

        init(_ data: Data, range: NSRange ) {
            self.data = data
            self.startIndex = range.location
            self.endIndex = range.location + range.length
        }

        subscript (position: Int) -> UInt8 {
            return data.withUnsafeBytes({ dataBytes -> UInt8 in
                dataBytes.bindMemory(to: UInt8.self)[position]
            })
        }
        subscript (bounds: Range<Int>) -> Data {
            return data.subdata(in: bounds)
        }
        fileprivate func formIndex(after i: inout Int) {
            i += 1
        }
        fileprivate func index(after i: Int) -> Int {
            return i + 1
        }
        var startIndex: Int
        var endIndex: Int
        var length: Int { return endIndex - startIndex }
    }
}
