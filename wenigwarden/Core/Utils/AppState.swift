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
import ServiceManagement

/// A class that manages the app's state and user data
class AppState: ObservableObject {
    // Singleton instance of AppState
    static let shared = AppState()

    // User data properties
    var deviceId: String = ""
    var url: String = ""
    var email: String = ""
    var enableTouchId: Bool = false
    var lastVaultSync: Date?
    var startOnBoot: Int = 0 /// -1: disabled, 0 not set, 1 enabled

    /// Private initializer to enforce singleton pattern
    private init() {
        // Retrieve stored values or provide default values
        deviceId = UserDefaults.standard.string(forKey: "deviceId") ?? UUID().uuidString
        url = UserDefaults.standard.string(forKey: "url") ?? "https://bitwarden.com"
        email = UserDefaults.standard.string(forKey: "email") ?? ""
        enableTouchId = UserDefaults.standard.bool(forKey: "enableTouchId")
        lastVaultSync = UserDefaults.standard.object(forKey: "lastVaultSync") as? Date
        startOnBoot = UserDefaults.standard.integer(forKey: "startOnBoot")

        // Keyboard event to trigger menu extra opening
        KeyboardShortcuts.onKeyUp(for: .toggleMenu) {
            self.toggleAppVisibility()
        }

        // Listen for lock event
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(
            forName: .init("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { _ in
            Vault.shared.lock()
        }

        // Launch on boot
        if startOnBoot != -1 && SMAppService.mainApp.status != .enabled {
            launchOnBoot()
        }
    }

    /// Launch app on boot
    func launchOnBoot() {
        // Ask for user consent
        let alert = NSAlert()
        alert.messageText = "Start at login"
        alert.informativeText = "Do you want to run wenigwarden at login"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Enable
            try? SMAppService.mainApp.register()

            startOnBoot = 1
            UserDefaults.standard.set(startOnBoot, forKey: "startOnBoot")
        } else {
            // Disable
            try? SMAppService.mainApp.unregister()

            // Save as disable
            startOnBoot = -1
            UserDefaults.standard.set(startOnBoot, forKey: "startOnBoot")
        }

    }

    /// Toggle app visibility
    public func toggleAppVisibility() {
        for window in NSApplication.shared.windows {
            (window.value(forKey: "statusItem")as? NSStatusItem)?.button?.performClick(nil)
        }
    }

    /// Persists the current state to UserDefaults
    public func persist() {
        UserDefaults.standard.set(url, forKey: "url")
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set(deviceId, forKey: "deviceId")
        UserDefaults.standard.set(enableTouchId, forKey: "enableTouchId")
        UserDefaults.standard.set(lastVaultSync, forKey: "lastVaultSync")
    }
}
