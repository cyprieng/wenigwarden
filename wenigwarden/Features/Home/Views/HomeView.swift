//
//  ContentView.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 19/08/2024.
//

import SwiftUI

/// The main home view of the application
struct HomeView: View {
    @ObservedObject private var vault = Vault.shared

    var body: some View {
        VStack {
            // Show the appropriate view based on the state of the vault
            if !vault.unlocked {
                LoginView() // Show login view if the vault is locked
            } else {
                CipherListView() // Show the list of ciphers otherwise
            }
        }
        .padding(20) // Add padding around the content
        .frame(width: 400) // Set the width of the view
    }
}
