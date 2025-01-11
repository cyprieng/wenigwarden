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
    @Published public var shakeTouchIdButton: Bool = false
    @Published public var isLoadingTouchId = false

    @Published public var lastVaultSync: String?

    /// Load inital value from AppState
    @MainActor
    public func loadInitialState() {
        enableTouchId = AppState.shared.enableTouchId

        // Load last sync date
        if let date = AppState.shared.lastVaultSync {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            lastVaultSync = df.string(from: date)
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
                shakeTouchIdButton = true
                try? await Task.sleep(for: .milliseconds(250))
                shakeTouchIdButton = false
            }
        }
    }

    /// Sync the vaule
    public func syncVault(_ refreshList: @escaping () -> Void) {
        Task {
            try await Vault.shared.updateVault()
            await self.loadInitialState()
            refreshList()
        }
    }
}
