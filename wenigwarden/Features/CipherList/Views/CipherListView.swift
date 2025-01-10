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

    /// Search field focus state
    @FocusState var isSearchFieldFocused: Bool

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            VStack {
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
                    ), goToDetails: {viewModel.goToDetails(cipher)})
                    .tag(index)
                    .listRowSeparatorTint(.gray)
                }
            }
            .frame(minHeight: viewModel.minHeight)
            .onAppear {
                viewModel.onGoToList()
            }
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
