//
//  VaultListView.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 23/08/2024.
//

import SwiftUI

/// A view representing the list of ciphers
struct CipherListView: View {
    /// View model for managing cipher list state and actions
    @StateObject private var viewModel = CipherListViewModel()

    /// Global application state
    @ObservedObject private var state = AppState.shared

    /// Search field focus state
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            VStack {
                reloginButtonIfNeeded
                toolbarSection
                cipherList
            }
            .navigationDestination(for: SettingsView.self) { $0 }
            .navigationDestination(for: CipherDetailsView.self) { $0 }
            .onChange(of: viewModel.path) { _, newValue in
                if newValue.isEmpty {
                    viewModel.onAppear()
                }
            }
        }
        .onAppear(perform: viewModel.loadInitialCiphers)
    }

    /// Relogin button shown when authentication is needed
    private var reloginButtonIfNeeded: some View {
        Group {
            if state.needRelogin {
                Button(action: Vault.shared.setUnlogged) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text("An error occured: you need to login again")
                    }
                }
            }
        }
    }

    /// Toolbar section containing search and settings
    private var toolbarSection: some View {
        HStack {
            searchField
            settingsButton
        }
    }

    /// Search field for filtering ciphers
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

    /// Settings button
    private var settingsButton: some View {
        Button(action: viewModel.goToSettings) {
            Image(systemName: "gear")
        }
    }

    /// List of ciphers with scroll functionality
    private var cipherList: some View {
        ScrollViewReader { proxy in
            List(selection: $viewModel.focusedCipherIndex) {
                cipherListContent
            }
            .frame(minHeight: viewModel.minHeight)
            .onAppear {
                viewModel.onAppear()
                viewModel.startSyncJob()
            }
            .onDisappear(perform: viewModel.stopSyncJob)
            .onChange(of: viewModel.focusedCipherIndex, initial: true) { _, target in
                if let target {
                    withAnimation {
                        proxy.scrollTo(target, anchor: .center)
                    }
                }
            }
        }
    }

    /// Content of the cipher list
    private var cipherListContent: some View {
        ForEach((viewModel.ciphers ?? []).indices, id: \.self) { index in
            cipherListItem(at: index)
        }
    }

    /// Individual cipher list item
    /// - Parameter index: Index of the cipher in the list
    private func cipherListItem(at index: Int) -> some View {
        let cipher = viewModel.ciphers![index]
        return CipherListItemView(
            cipher: Binding(
                get: { cipher },
                set: { _ in }
            ),
            goToDetails: { viewModel.goToDetails(cipher, index: index) }
        )
        .tag(index)
        .listRowSeparatorTint(.gray)
    }
}
