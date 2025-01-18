//
//  ContentView.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 19/08/2024.
//

import SwiftUI

/// The main home view of the application
struct HomeView: View {
    @ObservedObject var vault = Vault.shared

    var body: some View {
        VStack {
            KeyEventHandling().frame(width: 0, height: 0)

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

// Avoid error sound on keydown when it's managed by the app itself
struct KeyEventHandling: NSViewRepresentable {
    class KeyView: NSView {
        func isManagedByThisView(_ event: NSEvent) -> Bool {
            return true
        }

        override var acceptsFirstResponder: Bool { true }
        override func keyDown(with event: NSEvent) {
            if !isManagedByThisView(event) {
                super.keyDown(with: event)
            }
        }
    }

    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        DispatchQueue.main.async { // wait till next event cycle
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
    }
}
