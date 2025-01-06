//
//  VaultListViewModel.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 27/08/2024.
//

import Foundation

// Default height for the list
let defaultMinHeight: CGFloat = 400

/// ViewModel for managing the list of ciphers
class CipherListViewModel: ObservableObject {
    /// The list of ciphers to display
    @Published var ciphers: [CipherModel]?

    /// The search query entered by the user
    @Published var searchQuery = ""

    // Min height for the view
    @Published var minHeight: CGFloat? = defaultMinHeight

    /// Loads the initial list of ciphers when the view appears
    public func loadInitialCiphers() {
        ciphers = Vault.shared.ciphersDecrypted
    }

    /// Performs a search based on the user's query
    /// - Parameter query: The search query entered by the user
    public func performSearch(_ query: String) {
        if query.isEmpty {
            ciphers = Vault.shared.ciphersDecrypted
        } else {
            ciphers = Vault.shared.search(query: query)
        }
    }
}
