//
//  SettingsView.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 06/01/2025.
//

import SwiftUI
import KeyboardShortcuts

/// The settings view
struct SettingsView: View, Hashable {
    @StateObject var viewModel = SettingsViewModel()
    var refreshList: () -> Void

    var body: some View {
        VStack {
            // Toggle to enable touch id
            Toggle("Enable Touch ID", isOn: $viewModel.enableTouchId)
                .toggleStyle(.switch)
                .onChange(of: viewModel.enableTouchId) {
                    viewModel.handleTouchIdChange()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            // Password input for TouchID
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Shortcut setting
            Form {
                KeyboardShortcuts.Recorder("Toggle menu shortcut:", name: .toggleMenu)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Sync
            Text("Sync vault")
                .fontWeight(.bold)
                .padding(.top, 16)
                .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.lastVaultSync != nil {
                Text("Last sync: \(viewModel.lastVaultSync!)")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            ButtonWithLoader(action: {
                viewModel.syncVault(refreshList)
            }, label: {
                Text("Sync vault now")
            }, isLoading: $viewModel.isLoadingSync, error: $viewModel.errorSync)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Lock vault
            Button("Lock vault") {
                Vault.shared.lock()
            }
            .padding(.top, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .navigationTitle("Settings")
        .onAppear(perform: viewModel.loadInitialState)
    }

    // Always equal
    static func == (lhs: SettingsView, rhs: SettingsView) -> Bool {
        return true
    }

    /// Staic hash
    func hash(into hasher: inout Hasher) {
        hasher.combine("settings")
    }
}
