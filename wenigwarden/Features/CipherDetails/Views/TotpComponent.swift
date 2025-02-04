//
//  Totp.swift
//  wenigwarden
//
//  Created by Cyprien Guillemot on 21/01/2025.
//

import SwiftUI
import SwiftOTP

/// A view component to display and manage TOTP codes
struct TotpComponent: View {
    /// Key code for copying TOTP value
    private let copyKeyCode: String

    /// Helper for managing TOTP generation and updates
    @StateObject private var totpHelper: TotpHelper

    /// Initialize TOTP component
    /// - Parameters:
    ///   - totpSecret: The secret key for TOTP generation
    ///   - copyKeyCode: Keyboard shortcut for copying TOTP
    init(totpSecret: String, copyKeyCode: String) {
        self.copyKeyCode = copyKeyCode
        self._totpHelper = StateObject(wrappedValue: TotpHelper(totpSecret: totpSecret))
    }

    var body: some View {
        GridRow {
            TextLabel(title: "TOTP")

            Text("\(totpHelper.currentTotp) (\(totpHelper.currentSeconds)s)")

            ClipboardButton(
                data: totpHelper.currentTotp,
                copyKeyCode: copyKeyCode
            )
        }
    }
}

/// Helper class for managing TOTP generation and updates
final class TotpHelper: ObservableObject {
    /// TOTP generator instance
    private var totp: TOTP?

    /// Current TOTP code
    @Published private(set) var currentTotp: String = ""

    /// Seconds remaining until next TOTP update
    @Published private(set) var currentSeconds: Int = 0

    /// Timer for TOTP updates
    private var updateTimer: Timer?

    /// Initialize TOTP helper
    /// - Parameter totpSecret: The secret key for TOTP generation
    init(totpSecret: String) {
        setupTOTP(with: totpSecret)
    }

    deinit {
        updateTimer?.invalidate()
    }

    /// Sets up TOTP generation with the provided secret
    private func setupTOTP(with secret: String) {
        guard let secretData = base32DecodeToData(extractSecretFromOTPAuth(secret)),
              let totp = TOTP(secret: secretData) else {
            return
        }

        self.totp = totp
        updateTotp()
        startUpdateTimer()
    }

    /// Starts the timer for TOTP updates
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in
            self?.updateTotp()
        }
    }

    /// Updates the current TOTP code and remaining seconds
    private func updateTotp() {
        if currentSeconds <= 1 {
            currentTotp = totp?.generate(time: Date.now) ?? ""
            currentSeconds = 30
        } else {
            currentSeconds -= 1
        }
    }

    /// Extracts TOTP secret from otpauth URL
    /// - Parameter input: Input string containing TOTP secret
    /// - Returns: Extracted secret or original input if not found
    private func extractSecretFromOTPAuth(_ input: String) -> String {
        guard input.hasPrefix("otpauth://totp/"),
              input.contains("secret="),
              let secretComponent = input.components(separatedBy: "&")
                .first(where: { $0.contains("secret=") }),
              let secret = secretComponent.components(separatedBy: "secret=").last else {
            return input
        }
        return secret
    }

    /// Decodes Base32 string to Data
    /// - Parameter string: Base32 encoded string
    /// - Returns: Decoded data or nil if invalid
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
