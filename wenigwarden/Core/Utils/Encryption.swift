import Foundation
import CommonCrypto
import CryptoSwift

// swiftlint:disable identifier_name

func generateMasterKey(email: String, password: String, kdfIterations: Int) -> Data? {
    return pbkdf2(hash: CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256),
                  passwordData: password.data(using: .utf8)!,
                  salt: email.lowercased().data(using: .utf8)!,
                  keyByteCount: 256/8,
                  rounds: kdfIterations)
}

func macsEqual(macKey: [UInt8], mac1: [UInt8], mac2: [UInt8]) -> Bool {
    do {
        let hmac1 = try HMAC(key: macKey, variant: .sha2(.sha256)).authenticate(mac1)
        let hmac2 = try HMAC(key: macKey, variant: .sha2(.sha256)).authenticate(mac2)
        return hmac1 == hmac2
    } catch {return false}

}

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

func decrypt(decKey: [UInt8]? = nil, encKey: [UInt8]? = nil, str: String) throws -> [UInt8] {
    // Break the encKey into the private key and mac digest
    var key: [UInt8]
    var macKey: [UInt8] = []

    if let encKey {
        key = Array(encKey.prefix(32))
        macKey = Array(encKey.suffix(32))
    } else if let decKey {
        key = decKey
    } else {
        key = Vault.shared.encKey!
    }

    // Break the encrypted string into it's iv and data components
    let split = str.components(separatedBy: "|")
    if split.count == 1 {
        return []
    }

    let iv = (Data(base64Encoded: String(split[0].dropFirst(2)))?.bytes)
    let ct = (Data(base64Encoded: split[1])?.bytes)
    let mac2 = (Data(base64Encoded: split[2])?.bytes)
    if split[0].prefix(1) == "2" {
        if key.count == 32 {
            macKey = hkdfStretch(prk: key, info: "mac", size: 32)
            key = hkdfStretch(prk: key, info: "enc", size: 32)
        } else if key.count == 64 {
            macKey = Array(key.suffix(32))
            key = Array(key.prefix(32))
        }
    }
    do {
        let mac1 = try HMAC(key: macKey, variant: .sha2(.sha256)).authenticate((iv ?? []) + (ct ?? []))
        if !macsEqual(macKey: macKey, mac1: mac1, mac2: mac2 ?? []) {
            return []
        }

        let aes = try AES(key: key, blockMode: CBC(iv: iv ?? []))
        let pt = try aes.decrypt(ct ?? [])

        return pt
    } catch {
        print("Error decrypting: \(error).")
        return []
    }
}

/// Decrypt data
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

func pemToPKCS1DER(_ pemKey: String) throws -> Data? {
    guard let derKey = try? PEM.PrivateKey.toDER(pemKey) else {
        return nil
    }
    guard let pkcs1DERKey = PKCS8.PrivateKey.stripHeaderIfAny(derKey) else {
        return nil
    }
    return pkcs1DERKey
}

class PKCS8 {
    class PrivateKey {
        // swiftlint:disable:next cyclomatic_complexity
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

        public static func stripHeaderIfAny(_ derKey: Data) -> Data? {
            guard let offset = getPKCS1DEROffset(derKey) else {
                return nil
            }
            return derKey.subdata(in: offset..<derKey.count)
        }
    }
}

class PEM {
    class PrivateKey {
        public static func toDER(_ pemKey: String) throws -> Data? {
            guard let data = PEM.base64Decode(pemKey) else {
                return nil
            }
            return data
        }
    }

    fileprivate static func base64Decode(_ base64Data: String) -> Data? {
        return Data(base64Encoded: base64Data, options: [.ignoreUnknownCharacters])
    }
}

extension Data {
    fileprivate var bytesView: BytesView { return BytesView(self) }

    fileprivate func bytesViewRange(_ range: NSRange) -> BytesView {
        return BytesView(self, range: range)
    }

    fileprivate struct BytesView: Collection {
        // The view retains the Data. That's on purpose.
        // Data doesn't retain the view, so there's no loop.
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
