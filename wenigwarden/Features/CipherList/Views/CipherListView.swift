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
        VStack {
            // Search field
            searchField

            // List of ciphers
            cipherList
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
            VStack(alignment: .leading) {
                CipherListItemView(cipher: cipher)
                    .onHover { _ in
                        NSCursor.pointingHand.set()
                    }
                    .onTapGesture {
                        viewModel.selectCipher(cipher)
                    }

                Divider()
                    .background(Color.gray.opacity(0.4))
            }
            .listRowSeparator(.hidden)
        }
        .frame(height: 400)
    }
}
