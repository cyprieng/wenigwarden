//
//  VaultItemDetailsView.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 26/08/2024.
//

import SwiftUI

/// A view representing the details of a cipher
struct CipherDetailsView: View {
    @State
    var cipher: CipherModel

    @State var isPasswordVisible: Bool = false

    var body: some View {
        ScrollView {
            VStack {
                detailRow(title: "Name", value: $cipher.name)

                if let login = cipher.login?.username, !login.isEmpty {
                    detailRow(title: "Login", value: Binding(
                        get: { cipher.login?.username ?? "" },
                        set: { newValue in cipher.login?.username = newValue }
                    ))
                }

                if let uri = cipher.login?.uri, !uri.isEmpty {
                    uriRow(uri: cipher.login!.uri!)
                }

                if let password = cipher.login?.password, !password.isEmpty {
                    passwordRow(password: Binding(
                        get: { cipher.login?.password ?? "" },
                        set: { newValue in cipher.login?.password = newValue }
                    ))
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .navigationTitle(cipher.name)
    }

    /// A row displaying a detail with a title and value
    private func detailRow(title: String, value: Binding<String>) -> some View {
        HStack {
            Text("\(title):")
                .bold()

            Text(value.wrappedValue)

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

            Text(isPasswordVisible ? password.wrappedValue : String(repeating: "•", count: 8))

            ClipboardButton(data: password.wrappedValue)
            togglePasswordVisibilityButton
        }
    }

    /// A button to toggle the visibility of the password
    private var togglePasswordVisibilityButton: some View {
        Button(action: { isPasswordVisible.toggle() }, label: {
            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
        })
    }
}
