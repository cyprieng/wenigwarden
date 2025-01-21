//
//  Totp.swift
//  wenigwarden
//
//  Created by Cyprien Guillemot on 21/01/2025.
//

import SwiftUI
import SwiftOTP

/// A component to show TOTP
struct TotpComponent: View {
    var copyKeyCode: String
    @ObservedObject private var totpHelper: TotpHelper

    /// Init totp with given secret
    init(totpSecret: String, copyKeyCode: String) {
        self.copyKeyCode = copyKeyCode
        self.totpHelper = .init(totpSecret: totpSecret)
    }

    var body: some View {
        GridRow {
            TextLabel(title: "TOTP")

            Text("\(totpHelper.currentTotp) (\(totpHelper.currentSeconds)s)")

            ClipboardButton(data: totpHelper.currentTotp, copyKeyCode: copyKeyCode)
        }
    }
}

/// TOTP helper
class TotpHelper: ObservableObject {
    var totp: TOTP?  // Lib TOTP
    var timer: Timer?  // Update timer

    @Published var currentTotp: String = ""  // Current totp
    @Published var currentSeconds: Int = 0  // Current seconds remaining

    /// Init with secret
    init(totpSecret: String) {
        if let totpSecretData = base32DecodeToData(extractSecretFromOTPAuth(totpSecret)) {
            // Init lib
            self.totp = TOTP(secret: totpSecretData)
            if self.totp != nil {
                // First totp
                self.updateTotp()

                // Update every seconds
                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {[weak self] timer in
                    guard let self = self else {
                        timer.invalidate()
                        return
                    }

                    self.updateTotp()
                }
            }
        }
    }

    /// Update OTP
    private func updateTotp() {
        if currentSeconds <= 1 {  // Otp is expired
            currentTotp = totp!.generate(time: Date.now) ?? ""
            currentSeconds = 30
        } else {  // Decrement
            currentSeconds -= 1
        }
    }

    /// Extract secret from string
    func extractSecretFromOTPAuth(_ input: String) -> String {
        // Check if string contains "otpauth://totp/" and "secret="
        if input.hasPrefix("otpauth://totp/") && input.contains("secret=") {
            // Split the string by "&" to get parameters
            let components = input.components(separatedBy: "&")

            // Find the component that contains "secret="
            if let secretComponent = components.first(where: { $0.contains("secret=") }) {
                // Split by "=" and get the secret value
                let secretParts = secretComponent.components(separatedBy: "secret=")
                if secretParts.count > 1 {
                    return secretParts[1]
                }
            }
        }

        // If pattern doesn't match or secret not found, return full string
        return input
    }

    /// Helper function to decode Base32
    private func base32DecodeToData(_ string: String) -> Data? {
        let base32Alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
        var bytes = [UInt8]()
        var buffer = 0
        var bitsRemaining = 0

        for char in string.uppercased() {
            guard let value = base32Alphabet.firstIndex(of: char) else {
                continue
            }

            buffer = (buffer << 5) | value
            bitsRemaining += 5

            while bitsRemaining >= 8 {
                bitsRemaining -= 8
                bytes.append(UInt8(buffer >> bitsRemaining))
                buffer &= (1 << bitsRemaining) - 1
            }
        }

        return Data(bytes)
    }
}
