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

    var body: some View {
        NavigationStack {
            VStack {
                // Search field
                searchField

                // List of ciphers
                cipherList
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
            .padding()
    }

    /// The list of ciphers
    private var cipherList: some View {
        List(viewModel.ciphers ?? []) { cipher in
            NavigationLink(
                destination: CipherDetailsView(cipher: cipher).onAppear {
                    // Remove the min height when going to cipher details
                    viewModel.minHeight = nil
                }.onDisappear {
                    // Re apply the min height when going back to the list
                    viewModel.minHeight = defaultMinHeight
                }
            ) {
                CipherListItemView(cipher: cipher)
            }
            .listRowSeparatorTint(.gray)
        }.frame(minHeight: viewModel.minHeight)
    }
}
