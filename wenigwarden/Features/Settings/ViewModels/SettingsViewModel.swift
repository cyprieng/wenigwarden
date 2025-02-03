//
//  SettingsViewModel.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 06/01/2025.
//

import Foundation

/// ViewModel for managing the settings
class SettingsViewModel: ObservableObject {
    // Touch id
    @Published internal var enableTouchId: Bool = false
    @Published internal var showPasswordInput: Bool = false
    @Published internal var password: String = ""
    @Published internal var errorTouchId: Bool = false
    @Published internal var isLoadingTouchId = false

    // Sync
    @Published internal var lastVaultSync: String?
    @Published internal var isLoadingSync = false
    @Published internal var errorSync = false

    // Version
    internal var version: String?
    internal var buildNumber: String?

    /// Load inital value from AppState
    @MainActor
    internal func loadInitialState() {
        enableTouchId = AppState.shared.enableTouchId

        // Load last sync date
        if let date = AppState.shared.lastVaultSync {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            lastVaultSync = dateFormatter.string(from: date)
        }

        // Get version
        version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    }

    /// Handle event when touch id value change
    internal func handleTouchIdChange() {
        if enableTouchId && !AppState.shared.enableTouchId {
            // Ask for password to enable touchid
            showPasswordInput = true
        } else if !enableTouchId {
            // Disable touchid
            showPasswordInput = false
            AppState.shared.enableTouchId = false
            AppState.shared.persist()
            Vault.shared.setTouchIdPassword("")
        }
    }

    /// Enable touch id
    @MainActor
    internal func doEnableTouchId() {
        // Abort if password is empty
        if password.isEmpty {
            return
        }

        Task {
            do {
                // Try to unlock
                isLoadingTouchId = true
                try await Vault.shared.unlock(password: password)
                isLoadingTouchId = false

                // Store password in touchid
                Vault.shared.setTouchIdPassword(password)
                password = ""
                AppState.shared.enableTouchId = true
                AppState.shared.persist()
                showPasswordInput = false
            } catch {
                // Indicate there was an error when using the provided password
                isLoadingTouchId = false
                errorTouchId = true
            }
        }
    }

    /// Sync the vaule
    @MainActor
    internal func syncVault(_ refreshList: @escaping () -> Void) {
        Task {
            self.isLoadingSync = true
            do {
                try await Vault.shared.updateVault()
                self.loadInitialState()
                refreshList()
            } catch {
                self.errorSync = true
            }
            self.isLoadingSync = false
        }
    }

    /// Logout action
    internal func logout() {
        AppState.shared.reset()
        Vault.shared.reset()
    }
}
