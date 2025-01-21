//
//  VaultItemDetailsView.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 26/08/2024.
//

import SwiftUI

/// A view representing the details of a cipher
struct CipherDetailsView: View, Hashable {
    @State
    var cipher: CipherModel

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 5, verticalSpacing: 15) {
            // Name
            DetailRow(title: "Name", value: cipher.name, copyKeyCode: "n")

            // Login
            if let login = cipher.login?.username, !login.isEmpty {
                DetailRow(title: "Login", value: cipher.login?.username ?? "", copyKeyCode: "l")
            }

            // URIs
            ForEach(0..<(cipher.login?.uris ?? []).count, id: \.self) { index in
                let uri = cipher.login!.uris![index]
                if !uri.uri.isEmpty {
                    UriRow(uri: uri.uri, copyKeyCode: index == 0 ? "u" : nil)
                }
            }

            // Password
            if let password = cipher.login?.password, !password.isEmpty {
                PasswordRow(title: "Password", password: cipher.login?.password ?? "", copyKeyCode: "p")
            }

            // Card details
            if let cardHolderName = cipher.card?.cardholderName, !cardHolderName.isEmpty {
                DetailRow(title: "Card holder name", value: cardHolderName, copyKeyCode: nil)
            }
            if let number = cipher.card?.number, !number.isEmpty {
                PasswordRow(title: "Card number", password: number, copyKeyCode: nil)
            }
            if let expMonth = cipher.card?.expMonth, !expMonth.isEmpty,
               let expYear = cipher.card?.expYear, !expYear.isEmpty {
                DetailRow(title: "Expiration", value: "\(expMonth)/\(expYear)", copyKeyCode: nil)
            }
            if let code = cipher.card?.code, !code.isEmpty {
                PasswordRow(title: "Code", password: code, copyKeyCode: nil)
            }

            // Notes
            if let notes = cipher.notes, !notes.isEmpty {
                Text("Notes:")
                    .bold()

                Text(notes)
                    .lineLimit(nil)
                    .truncationMode(.tail)
            }

            // Custom fields
            if let fields = cipher.fields, !fields.isEmpty {
                Text("Custom fields:")
                    .bold()

                ForEach(fields) { field in
                    if let value = field.value, !value.isEmpty {
                        if field.type == 1 {
                            PasswordRow(title: "Password", password: value, copyKeyCode: nil)
                        } else {
                            DetailRow(title: field.name, value: value, copyKeyCode: nil)
                        }
                    }
                }
            }

            // TOTP
            if let totp = cipher.login?.totp, !totp.isEmpty {
                TotpComponent(totpSecret: totp, copyKeyCode: "t")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
        .navigationTitle(cipher.name)
    }

    /// Check equality
    static func == (lhs: CipherDetailsView, rhs: CipherDetailsView) -> Bool {
        lhs.cipher.id == rhs.cipher.id
    }

    /// Get hash
    func hash(into hasher: inout Hasher) {
        hasher.combine(cipher.id)
    }
}
