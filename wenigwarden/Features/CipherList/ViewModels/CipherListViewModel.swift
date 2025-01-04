//
//  VaultListViewModel.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 27/08/2024.
//

import Foundation

/// ViewModel for managing the list of ciphers
class CipherListViewModel: ObservableObject {
    /// The list of ciphers to display
    @Published var ciphers: [CipherModel]?

    /// The search query entered by the user
    @Published var searchQuery = ""

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

    /// Selects a cipher
    /// - Parameter cipher: The cipher to select
    public func selectCipher(_ cipher: CipherModel) {
        AppState.shared.cipherSelected = cipher
    }

    /// Deselects the current cipher
    public func deselectCipher() {
        AppState.shared.cipherSelected = nil
    }
}
