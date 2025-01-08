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
    @Published var url: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading = false
    @Published var error: Error?
    @Published var shakeButton: Bool = false

    /// Checks if the form is valid
    var isFormValid: Bool {
        !url.isEmpty && !email.isEmpty && !password.isEmpty
    }

    /// Loads initial values from AppState
    @MainActor
    func loadInitialValues() {
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
    public func submitForm() {
        guard isFormValid else { return }
        Task {
            do {
                isLoading = true
                try await login()
                isLoading = false
            } catch {
                isLoading = false
                shakeButton = true
                try? await Task.sleep(for: .milliseconds(250))
                shakeButton = false
            }
        }
    }

    /// Performs the login action
    public func login() async throws {
        // Save data in app state service
        let vault = Vault.shared
        let appState = AppState.shared
        appState.email = email
        appState.url = url
        appState.persist()

        // We can unlock directly if already logged in but not unlocked
        if vault.logged && !vault.unlocked {
            do {
                try await Vault.shared.unlock(password: password)

                // Start login in background to ensure vault is up to date
                Task {
                    try await vault.login(email: email, url: url, password: password)
                }
            } catch {
                // Unlock through API if direct unlock fails
                try await vault.login(email: email, url: url, password: password)
            }
        } else {
            // Perform login through API
            try await vault.login(email: email, url: url, password: password)
        }
    }
}
