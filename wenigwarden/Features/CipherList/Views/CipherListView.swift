//
//  VaultListView.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 23/08/2024.
//

import SwiftUI

/// A view representing the list of ciphers
struct CipherListView: View {
    @ObservedObject var viewModel = CipherListViewModel()
    @ObservedObject var state = AppState.shared

    /// Search field focus state
    @FocusState var isSearchFieldFocused: Bool

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            VStack {
                // Relogin button
                if state.needRelogin {
                    Button(action: {
                        Vault.shared.logged = false
                        Vault.shared.unlocked = false
                    }, label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text("An error occured: you need to login again")
                        }
                    })
                }

                HStack {
                    // Search field
                    searchField

                    // Settings link
                    Button(action: {
                        viewModel.goToSettings()
                    }, label: {
                        Image(systemName: "gear")
                    })
                }

                // List of ciphers
                cipherList
            }.navigationDestination(for: SettingsView.self) { settingsView in
                // Link for settings
                settingsView
            }
            .navigationDestination(for: CipherDetailsView.self) { detailView in
                // Link for cipher details
                detailView
            }
            .onChange(of: viewModel.path) { _, newValue in
                if newValue.isEmpty {
                    viewModel.onAppear()
                }
            }
        }
        .onAppear(perform: viewModel.loadInitialCiphers)
    }

    /// The search field for filtering ciphers
    private var searchField: some View {
        TextField("Search", text: $viewModel.searchQuery)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onChange(of: viewModel.searchQuery) { _, newValue in
                viewModel.performSearch(newValue)
            }
            .onChange(of: viewModel.isSearchFieldFocused, initial: true) { _, newValue in
                isSearchFieldFocused = newValue
            }
            .onChange(of: isSearchFieldFocused, initial: true) { _, newValue in
                viewModel.isSearchFieldFocused = newValue
            }
            .focused($isSearchFieldFocused)
    }

    /// The list of ciphers
    private var cipherList: some View {
        ScrollViewReader { proxy in
            List(selection: $viewModel.focusedCipherIndex) {
                ForEach((viewModel.ciphers ?? []).indices, id: \.self) { index in
                    let cipher = viewModel.ciphers![index]
                    CipherListItemView(cipher: Binding(
                        get: { return cipher},
                        set: { _ in }
                    ), goToDetails: {viewModel.goToDetails(cipher, index: index)})
                    .tag(index)
                    .listRowSeparatorTint(.gray)
                }
            }
            .frame(minHeight: viewModel.minHeight)
            .onAppear {
                viewModel.onAppear()
                viewModel.startSyncJob()
            }
            .onDisappear(perform: viewModel.stopSyncJob)
            .onChange(of: viewModel.focusedCipherIndex, initial: true) { _, target in
                // Scroll to currently selected item
                if let target = target {
                    withAnimation {
                        proxy.scrollTo(target, anchor: .center)
                    }
                }
            }
        }
    }
}
