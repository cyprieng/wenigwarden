//
//  VaultItemDetailsView.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 26/08/2024.
//

import SwiftUI

/// A view representing the details of a cipher
struct CipherDetailsView: View {
    @StateObject var viewModel = CipherDetailsViewModel()

    var body: some View {
        VStack {
            HStack {
                backButton

                Spacer()

                Text("Show details")

                Spacer()

                editButton
            }
            .padding([.bottom], 30)

            detailsContent()
        }
        .onAppear(perform: viewModel.loadInitialCipher)
    }

    /// The back button to deselect the cipher
    private var backButton: some View {
        Button(action: { AppState.shared.cipherSelected = nil }, label: {
            Label("Back", systemImage: "arrow.left")
        })
    }

    /// The edit button to toggle edit mode
    private var editButton: some View {
        if viewModel.isEditing {
            Button(action: {
                viewModel.isEditing = false
            }, label: {
                Label("Save", systemImage: "square.and.arrow.down")
            })
        } else {
            Button(action: {
                viewModel.isEditing = true
            }, label: {
                Label("Edit", systemImage: "square.and.pencil")
            })
        }
    }

    /// The content view displaying the details of the cipher
    @ViewBuilder
    private func detailsContent() -> some View {
        detailRow(title: "Name", value: $viewModel.name)

        if !viewModel.username.isEmpty {
            detailRow(title: "Login", value: $viewModel.username)
        }

        if !viewModel.uri.isEmpty {
            uriRow(uri: viewModel.uri)
        }

        passwordRow(password: $viewModel.password)
    }

    /// A row displaying a detail with a title and value
    private func detailRow(title: String, value: Binding<String>) -> some View {
        HStack {
            Text("\(title):")
                .bold()

            if viewModel.isEditing {
                TextField("\(title)", text: value)
            } else {
                Text(value.wrappedValue)
            }
            ClipboardButton(data: value.wrappedValue)
        }
    }

    /// A row displaying the URI with a clickable link
    private func uriRow(uri: String) -> some View {
        HStack {
            Text("URI:")
                .bold()
            Link(uri, destination: URL(string: uri) ?? URL(string: "https://")!)
                .lineLimit(1)
                .truncationMode(.middle)
            ClipboardButton(data: uri)
        }
        .onHover { _ in
            NSCursor.pointingHand.set()
        }
    }

    /// A row displaying the password with a toggle for visibility
    private func passwordRow(password: Binding<String>) -> some View {
        HStack {
            Text("Password:")
                .bold()

            if viewModel.isEditing {
                if viewModel.isPasswordVisible {
                    TextField("Password", text: password)
                        .textContentType(.password)
                } else {
                    SecureField("Password", text: password)
                        .textContentType(.password)
                }
            } else {
                Text(viewModel.isPasswordVisible ? password.wrappedValue : String(repeating: "•", count: 8))
            }

            ClipboardButton(data: password.wrappedValue)
            togglePasswordVisibilityButton
        }
    }

    /// A button to toggle the visibility of the password
    private var togglePasswordVisibilityButton: some View {
        Button(action: { viewModel.isPasswordVisible.toggle() }, label: {
            Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
        })
    }
}
