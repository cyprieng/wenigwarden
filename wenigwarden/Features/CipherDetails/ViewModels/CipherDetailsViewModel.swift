//
//  VaultItemDetailsViewModel.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 27/08/2024.
//

import Foundation

/// ViewModel for managing the details of a cipher
class CipherDetailsViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var uri: String = ""

    @Published var isPasswordVisible = false
    @Published var isEditing = false

    /// Loads the initial details of the selected cipher
    public func loadInitialCipher() {
        if let selectedCipher = AppState.shared.cipherSelected {
            name = selectedCipher.name
            username = selectedCipher.login?.username ?? ""
            password = selectedCipher.login?.password ?? ""
            uri = selectedCipher.login?.uri ?? ""
        }
    }
}
