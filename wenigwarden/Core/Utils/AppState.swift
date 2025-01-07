//
//  AppState.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 19/08/2024.
//

import Foundation
import SwiftUICore
import KeyboardShortcuts
import AppKit

/// A class that manages the app's state and user data
class AppState: ObservableObject {
    // Singleton instance of AppState
    static let shared = AppState()

    // User data properties
    var deviceId: String = ""
    var url: String = ""
    var email: String = ""
    var enableTouchId: Bool = false

    /// Private initializer to enforce singleton pattern
    private init() {
        // Retrieve stored values or provide default values
        deviceId = UserDefaults.standard.string(forKey: "deviceId") ?? UUID().uuidString
        url = UserDefaults.standard.string(forKey: "url") ?? "https://bitwarden.com"
        email = UserDefaults.standard.string(forKey: "email") ?? ""
        enableTouchId = UserDefaults.standard.bool(forKey: "enableTouchId")

        // Keyboard event to trigger menu extra opening
        KeyboardShortcuts.onKeyUp(for: .toggleMenu) { [self] in
            for window in NSApplication.shared.windows {
                (window.value(forKey: "statusItem")as? NSStatusItem)?.button?.performClick(nil)
            }
        }
    }

    /// Persists the current state to UserDefaults
    public func persist() {
        UserDefaults.standard.set(url, forKey: "url")
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set(deviceId, forKey: "deviceId")
        UserDefaults.standard.set(enableTouchId, forKey: "enableTouchId")
    }
}
