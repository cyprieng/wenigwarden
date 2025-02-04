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
import Sparkle

/// A class that manages the app's state and user data
final class AppState: ObservableObject {
    // Singleton instance of AppState
    static let shared = AppState()

    // User data properties
    var deviceId: String = ""
    var hostType: BitwardenHost = .com
    var url: String = ""
    var email: String = ""
    var enableTouchId: Bool = false
    var lastVaultSync: Date?

    // Flag indicating that a relog is necessary
    @Published var needRelogin: Bool = false

    // Sparkle update controller
    public let updaterController: SPUStandardUpdaterController

    /// Private initializer to enforce singleton pattern
    private init() {
        // Init sparkle updater
        updaterController = SPUStandardUpdaterController(startingUpdater: true,
                                                         updaterDelegate: nil,
                                                         userDriverDelegate: nil)
        self.updaterController.updater.checkForUpdatesInBackground()

        // Retrieve stored values or provide default values
        deviceId = UserDefaults.standard.string(forKey: "deviceId") ?? ""

        if deviceId.isEmpty {
            deviceId = UUID().uuidString
        }

        if let savedHost = UserDefaults.standard.string(forKey: "hostType"),
           let type = BitwardenHost(rawValue: savedHost) {
            hostType = type
        }

        url = UserDefaults.standard.string(forKey: "url") ?? ""
        email = UserDefaults.standard.string(forKey: "email") ?? ""
        enableTouchId = UserDefaults.standard.bool(forKey: "enableTouchId")
        lastVaultSync = UserDefaults.standard.object(forKey: "lastVaultSync") as? Date

        setupKeyboardShortcuts()
        setupLockScreenObserver()
    }

    /// Sets up keyboard shortcuts
    private func setupKeyboardShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .toggleMenu) { [weak self] in
            self?.toggleAppVisibility()
        }
    }

    /// Sets up lock screen observer
    private func setupLockScreenObserver() {
        DistributedNotificationCenter.default().addObserver(
            forName: .init("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { _ in
            Vault.shared.lock()
        }
    }

    /// Toggle app visibility
    internal func toggleAppVisibility() {
        for window in NSApplication.shared.windows {
            (window.value(forKey: "statusItem")as? NSStatusItem)?.button?.performClick(nil)
        }
    }

    /// Persists the current state to UserDefaults
    internal func persist() {
        UserDefaults.standard.set(hostType.rawValue, forKey: "hostType")
        UserDefaults.standard.set(url, forKey: "url")
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set(deviceId, forKey: "deviceId")
        UserDefaults.standard.set(enableTouchId, forKey: "enableTouchId")
        UserDefaults.standard.set(lastVaultSync, forKey: "lastVaultSync")
    }

    /// Reset current app state
    internal func reset() {
        let keysToRemove = ["hostType", "url", "email", "deviceId", "enableTouchId", "lastVaultSync"]

        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }

        UserDefaults.standard.synchronize()

        hostType = .com
        deviceId = ""
        url = ""
        email = ""
        enableTouchId = false
        lastVaultSync = nil
    }
}
