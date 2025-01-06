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

    /// Load inital value from AppState
    public func loadInitialState() {
        enableTouchId = AppState.shared.enableTouchId
    }

    /// Ask password when enabling touchid
    public func askPassword() {
        showPasswordInput = true
    }

    public func doEnableTouchId() {

    }

    public func doDisableTouchId() {
        showPasswordInput = false
    }
}
