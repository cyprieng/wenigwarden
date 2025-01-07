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
            Grid(alignment: .leading, horizontalSpacing: 5, verticalSpacing: 15) {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
            .navigationTitle(cipher.name)
        }

    /// A row displaying a detail with a title and value
    private func detailRow(title: String, value: Binding<String>) -> some View {
        GridRow {
            Text("\(title):")
                .bold()

            Text(value.wrappedValue).lineLimit(1)
                .truncationMode(.tail).frame(width: 200, alignment: .leading)

            ClipboardButton(data: value.wrappedValue).frame(alignment: .trailing)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    /// A row displaying the URI with a clickable link
    private func uriRow(uri: String) -> some View {
        GridRow {
            Text("URI:")
                .bold()

            Link(destination: URL(string: uri) ?? URL(string: "https://")!) {
                Text(uri).lineLimit(1)
                    .truncationMode(.tail).frame(width: 200, alignment: .leading)
            }

            ClipboardButton(data: uri).frame(alignment: .trailing)
        }
        .onHover { _ in
            NSCursor.pointingHand.set()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// A row displaying the password with a toggle for visibility
    private func passwordRow(password: Binding<String>) -> some View {
        GridRow {
            Text("Password:")
                .bold()

            Text(isPasswordVisible ? password.wrappedValue : String(repeating: "•", count: 8)).lineLimit(1)
                .truncationMode(.tail).frame(width: 200, alignment: .leading)

            HStack {
                ClipboardButton(data: password.wrappedValue)
                togglePasswordVisibilityButton
            }.frame(alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// A button to toggle the visibility of the password
    private var togglePasswordVisibilityButton: some View {
        Button(action: { isPasswordVisible.toggle() }, label: {
            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
        })
    }
}
