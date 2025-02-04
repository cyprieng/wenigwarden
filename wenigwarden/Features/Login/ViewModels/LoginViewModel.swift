//
//  LoginViewModel.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 27/08/2024.
//

import Foundation
import SwiftUI

/// ViewModel for managing the login screen
class LoginViewModel: ObservableObject {
    @Published var hostType: BitwardenHost = .com
    @Published var url: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading = false
    @Published var error: Bool = false
    @Published var otpNeeded: Bool = false

    /// Checks if the form is valid
    var isFormValid: Bool {
        (hostType != .selfHosted || !url.isEmpty) && !email.isEmpty && !password.isEmpty
    }

    /// Loads initial values from AppState
    @MainActor
    func loadInitialValues() {
        hostType = AppState.shared.hostType
        url = AppState.shared.url
        email = AppState.shared.email

        // Login with touch id if enabled
        Task {
            if AppState.shared.enableTouchId {
                let password = Vault.shared.getTouchIdPassword()
                if password != nil {
                    self.password = password!
                    self.submitForm()
                }
            }
        }
    }

    /// Submits the login form
    @MainActor
    internal func submitForm() {
        self.submitForm(otp: nil)
    }

    /// Submits the login form
    @MainActor
    internal func submitForm(otp: String? = nil) {
        guard isFormValid else { return }
        Task {
            do {
                isLoading = true
                try await login(otp: otp)
                isLoading = false
            } catch let error {
                isLoading = false
                if let errorResponse = error as? ErrorResponse,
                   let description = errorResponse.errorDescription,
                   description == "Two factor required." {
                    // Save two factor provider
                    if !(errorResponse.twoFactorProviders?.isEmpty ?? false) {
                        BitwardenAPI.shared.twoFactorProvider = errorResponse.twoFactorProviders![0].stringValue
                    }
                    self.otpNeeded = true
                } else {
                    self.error = true
                }
            }
        }
    }

    /// Performs the login action
    internal func login(otp: String? = nil) async throws {
        // Save data in app state service
        let vault = Vault.shared
        let appState = AppState.shared
        appState.email = email
        appState.hostType = hostType
        appState.url = url
        appState.persist()

        BitwardenAPI.shared.selfHostedURL = url
        BitwardenAPI.shared.host = hostType

        // We can unlock directly if already logged in but not unlocked
        if vault.logged && !vault.unlocked {
            do {
                try await Vault.shared.unlock(password: password)

                // Update vault in background to ensure vault is up to date
                Task {
                    try await vault.updateVault()
                }
            } catch {
                // Unlock through API if direct unlock fails
                try await vault.login(email: email, password: password, otp: otp)
            }
        } else {
            // Perform login through API
            try await vault.login(email: email, password: password, otp: otp)
        }
    }
}
