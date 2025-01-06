//
//  SettingsView.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 06/01/2025.
//

import SwiftUI

/// The settings view
struct SettingsView: View {
    @ObservedObject var viewModel = SettingsViewModel()

    var body: some View {
        VStack {
            Toggle("Enable Touch ID", isOn: $viewModel.enableTouchId)
                .toggleStyle(.switch)
                .onChange(of: viewModel.enableTouchId) {
                    if viewModel.enableTouchId {
                        viewModel.askPassword()
                    } else {
                        viewModel.doDisableTouchId()
                    }
                }

            if viewModel.showPasswordInput {
                HStack {
                    SecureField("Password", text: $viewModel.password).frame(width: 200)
                    Button("Enable", action: viewModel.doEnableTouchId)
                        .buttonStyle(.borderedProminent)
                }
            }
        }.padding(.vertical, 16)
        .navigationTitle("Settings")
        .frame(alignment: .leading)
        .onAppear {viewModel.loadInitialState()}
    }
}
