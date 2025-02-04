//
//  SettingsView.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 06/01/2025.
//

import SwiftUI
import KeyboardShortcuts
import ServiceManagement
import Sparkle

// This view model class publishes when new updates can be checked by the user
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

// This is the view for the Check for Updates menu item
// Note this intermediate view is necessary for the disabled state on the menu item to work properly before Monterey.
// See https://stackoverflow.com/questions/68553092/menu-not-updating-swiftui-bug for more info
struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater

        // Create our view model for our CheckForUpdatesView
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }

    var body: some View {
        Button("Check for Updates…", action: updater.checkForUpdates)
            .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

/// The settings view that displays and manages application settings
struct SettingsView: View, Hashable {
    /// View model that manages the settings state and business logic
    @StateObject private var viewModel = SettingsViewModel()

    /// Callback to refresh the main list when settings change
    private let refreshList: () -> Void

    /// Initialize settings view with a refresh callback
    /// - Parameter refreshList: Callback function to refresh the main list
    init(refreshList: @escaping () -> Void) {
        self.refreshList = refreshList
    }

    /// Main view body that composes all settings sections
    var body: some View {
        VStack {
            touchIdSection
            shortcutSection
            startupSection
            syncSection
            securitySection
            quitSection
            versionSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .navigationTitle("Settings")
        .onAppear(perform: viewModel.loadInitialState)
    }

    /// Section that manages Touch ID settings and password input
    private var touchIdSection: some View {
        VStack(alignment: .leading) {
            Toggle("Enable Touch ID", isOn: $viewModel.enableTouchId)
                .toggleStyle(.switch)
                .onChange(of: viewModel.enableTouchId) {
                    viewModel.handleTouchIdChange()
                }

            if viewModel.showPasswordInput {
                HStack {
                    SecureField("Password", text: $viewModel.password)
                        .frame(width: 200)
                        .onSubmit(viewModel.doEnableTouchId)

                    ButtonWithLoader(action: viewModel.doEnableTouchId, label: {
                        Text("Enable Touch ID")
                    }, isLoading: $viewModel.isLoadingTouchId, error: $viewModel.errorTouchId)
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.password.isEmpty)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Section for keyboard shortcut configuration
    private var shortcutSection: some View {
        Form {
            KeyboardShortcuts.Recorder("Toggle menu shortcut:", name: .toggleMenu)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Section to manage application startup settings
    private var startupSection: some View {
        Toggle(
            "Start at login",
            isOn: Binding(
                get: { SMAppService.mainApp.status == .enabled },
                set: { isEnabled in
                    if isEnabled {
                        try? SMAppService.mainApp.register()
                    } else {
                        try? SMAppService.mainApp.unregister()
                    }
                }
            )
        )
        .toggleStyle(.switch)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Section for vault synchronization controls and status
    private var syncSection: some View {
        VStack(alignment: .leading) {
            Text("Sync vault")
                .fontWeight(.bold)
                .padding(.top, 16)

            if let lastSync = viewModel.lastVaultSync {
                Text("Last sync: \(lastSync)")
            }

            ButtonWithLoader(action: {
                viewModel.syncVault(refreshList)
            }, label: {
                Text("Sync vault now")
            }, isLoading: $viewModel.isLoadingSync, error: $viewModel.errorSync)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Section for security-related actions like locking vault and logout
    private var securitySection: some View {
        VStack(alignment: .leading) {
            Button("Lock vault") {
                Vault.shared.lock()
            }
            .padding(.top, 16)

            Button("Log out", action: viewModel.logout)
                .padding(.top, 16)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Section for quit button
    private var quitSection: some View {
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .padding(.top, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Section displaying application version information
    private var versionSection: some View {
        VStack {
            // Update button
            CheckForUpdatesView(updater: AppState.shared.updaterController.updater)

            Text("Version: \(viewModel.version ?? "") (Build \(viewModel.buildNumber ?? ""))")
        }
    }
}

// MARK: - Hashable Implementation
extension SettingsView {
    /// Equality comparison for SettingsView
    /// - Returns: Always returns true as settings view is static
    static func == (lhs: SettingsView, rhs: SettingsView) -> Bool {
        true
    }

    /// Hashing implementation for SettingsView
    /// - Parameter hasher: Hasher to use for hashing
    func hash(into hasher: inout Hasher) {
        hasher.combine("settings")
    }
}
