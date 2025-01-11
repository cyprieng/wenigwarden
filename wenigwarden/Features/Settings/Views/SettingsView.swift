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

            // Password input for TouchID
            if viewModel.showPasswordInput {
                HStack {
                    SecureField("Password", text: $viewModel.password)
                        .frame(width: 200)
                        .onSubmit(viewModel.doEnableTouchId)
                    Button(action: viewModel.doEnableTouchId) {
                        if viewModel.isLoadingTouchId {
                            // Loader
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.7)
                        } else {
                            Text("Enable Touch ID")
                        }
                    }.buttonStyle(.borderedProminent)
                    .disabled(viewModel.password.isEmpty)
                    .modifier(ShakeEffect(shakes: viewModel.shakeTouchIdButton ? 2 : 0))
                    .animation(.default, value: viewModel.shakeTouchIdButton)
                }
            }

            // Shortcut setting
            Form {
                KeyboardShortcuts.Recorder("Toggle menu:", name: .toggleMenu)
            }

            // Sync
            if viewModel.lastVaultSync != nil {
                Text("Last sync: \(viewModel.lastVaultSync!)")

                Button("Sync now") {
                    viewModel.syncVault(refreshList)
                }
            }
        }.padding(.vertical, 16)
        .navigationTitle("Settings")
        .frame(alignment: .leading)
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
