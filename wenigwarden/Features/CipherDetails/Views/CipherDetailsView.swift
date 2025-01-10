//
//  VaultItemDetailsView.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 26/08/2024.
//

import SwiftUI

/// A view representing the details of a cipher
struct CipherDetailsView: View, Hashable {
    /// Check equality
    static func == (lhs: CipherDetailsView, rhs: CipherDetailsView) -> Bool {
        lhs.cipher.id == rhs.cipher.id
    }

    /// Get hash
    func hash(into hasher: inout Hasher) {
        hasher.combine(cipher.id)
    }

    @State
    var cipher: CipherModel

    @State var isPasswordVisible: Bool = false

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 5, verticalSpacing: 15) {
            // Name
            detailRow(title: "Name", value: $cipher.name, copyKeyCode: "n")

            // Login
            if let login = cipher.login?.username, !login.isEmpty {
                detailRow(title: "Login", value: Binding(
                    get: { cipher.login?.username ?? "" },
                    set: { newValue in cipher.login?.username = newValue }
                ), copyKeyCode: "l")
            }

            // URI
            if let uri = cipher.login?.uri, !uri.isEmpty {
                uriRow(uri: cipher.login!.uri!, copyKeyCode: "u")
            }

            // Password
            if let password = cipher.login?.password, !password.isEmpty {
                passwordRow(password: Binding(
                    get: { cipher.login?.password ?? "" },
                    set: { newValue in cipher.login?.password = newValue }
                ), copyKeyCode: "p")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
        .navigationTitle(cipher.name)
    }

    /// Text label component
    private func textLabel(_ title: String) -> some View {
        Text("\(title):")
            .bold()
    }

    /// Text value component
    private func textValue(_ text: String) -> some View {
        Text(text)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(width: 200, alignment: .leading)
    }

    /// A row displaying a detail with a title and value
    private func detailRow(title: String, value: Binding<String>, copyKeyCode: String? = nil) -> some View {
        GridRow {
            textLabel(title)

            textValue(value.wrappedValue)

            ClipboardButton(data: value.wrappedValue, copyKeyCode: copyKeyCode)
        }
    }

    /// A row displaying the URI with a clickable link
    private func uriRow(uri: String, copyKeyCode: String? = nil) -> some View {
        GridRow {
            textLabel("URI")

            Link(destination: URL(string: uri) ?? URL(string: "https://")!) {
                textValue(uri)
            }.onHover { _ in
                NSCursor.pointingHand.set()
            }

            ClipboardButton(data: uri, copyKeyCode: copyKeyCode)
        }
    }

    /// A row displaying the password with a toggle for visibility
    private func passwordRow(password: Binding<String>, copyKeyCode: String? = nil) -> some View {
        GridRow {
            textLabel("Password")

            textValue(isPasswordVisible ? password.wrappedValue : String(repeating: "•", count: 8))

            HStack {
                ClipboardButton(data: password.wrappedValue, copyKeyCode: copyKeyCode)
                togglePasswordVisibilityButton
            }
        }
    }

    /// A button to toggle the visibility of the password
    private var togglePasswordVisibilityButton: some View {
        Button(action: { isPasswordVisible.toggle() }, label: {
            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
        })
    }
}
