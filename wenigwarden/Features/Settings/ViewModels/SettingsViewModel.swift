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
    @Published public var enableTouchId: Bool = false
    @Published public var showPasswordInput: Bool = false
    @Published public var password: String = ""
    @Published public var errorTouchId: Bool = false
    @Published public var isLoadingTouchId = false

    // Sync
    @Published public var lastVaultSync: String?
    @Published public var isLoadingSync = false
    @Published public var errorSync = false

    /// Load inital value from AppState
    @MainActor
    public func loadInitialState() {
        enableTouchId = AppState.shared.enableTouchId

        // Load last sync date
        if let date = AppState.shared.lastVaultSync {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            lastVaultSync = dateFormatter.string(from: date)
        }
    }

    /// Handle event when touch id value change
    public func handleTouchIdChange() {
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
    public func doEnableTouchId() {
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
    public func syncVault(_ refreshList: @escaping () -> Void) {
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
}
