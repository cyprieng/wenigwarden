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
                    NavigationLink(destination: SettingsView().onAppear {
                        viewModel.onDisappear()
                    }.onDisappear {
                        viewModel.onGoToList()
                    }) {
                        Image(systemName: "gear")
                    }
                }

                // List of ciphers
                cipherList
            }.navigationDestination(for: CipherDetailsView.self) { detailView in
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
                    CipherListItemView(cipher: cipher)
                        .tag(index)
                        .listRowSeparatorTint(.gray)
                        .gesture(TapGesture().onEnded {
                            // Click to go to details
                            viewModel.goToDetails(cipher)
                        })
                }
            }
            .frame(minHeight: viewModel.minHeight)
            .onAppear {
                viewModel.onGoToList()
            }
            .onDisappear {
                viewModel.onDisappear()
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
