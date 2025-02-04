//
//  VaultItemDetailsView.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 26/08/2024.
//

import SwiftUI

/// A view that displays detailed information about a cipher, including basic info, login details,
/// card information, identity details, notes, custom fields, TOTP, and attachments
struct CipherDetailsView: View, Hashable {
    /// The cipher model to display
    @State private var cipher: CipherModel

    /// Initialize cipher details view
    /// - Parameter cipher: The cipher model to display
    init(cipher: CipherModel) {
        self._cipher = State(initialValue: cipher)
    }

    /// The main view body that arranges all cipher information in a grid layout
    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 5, verticalSpacing: 15) {
            basicInfo
            loginInfo
            cardInfo
            identityInfo
            notesInfo
            customFieldsInfo
            totpInfo
            attachmentsInfo
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
        .navigationTitle(cipher.name)
    }

    /// Displays the basic information of the cipher (name)
    private var basicInfo: some View {
        DetailRow(title: "Name", value: cipher.name, copyKeyCode: "n")
    }

    /// Displays login-related information including username, URIs, and password
    private var loginInfo: some View {
        Group {
            if let login = cipher.login?.username, !login.isEmpty {
                DetailRow(title: "Login", value: login, copyKeyCode: "l")
            }

            ForEach(0..<(cipher.login?.uris?.count ?? 0), id: \.self) { index in
                if let uri = cipher.login?.uris?[index].uri, !uri.isEmpty {
                    UriRow(uri: uri, copyKeyCode: index == 0 ? "u" : nil)
                }
            }

            if let password = cipher.login?.password, !password.isEmpty {
                PasswordRow(title: "Password", password: password, copyKeyCode: "p")
            }
        }
    }

    /// Displays card-related information including cardholder name, card number,
    /// expiration date, and security code
    private var cardInfo: some View {
        Group {
            if let card = cipher.card {
                if let cardholderName = card.cardholderName {
                    DetailRow(title: "Card holder name", value: cardholderName)
                }

                if let number = card.number {
                    PasswordRow(title: "Card number", password: number)
                }

                if let expMonth = card.expMonth,
                   let expYear = card.expYear {
                    DetailRow(title: "Expiration", value: "\(expMonth)/\(expYear)")
                }

                if let code = card.code {
                    PasswordRow(title: "Code", password: code)
                }
            }
        }
    }

    /// Displays identity-related information including personal details,
    /// contact information, and address details
    private var identityInfo: some View {
        Group {
            if let identity = cipher.identity {
                if let title = identity.title {
                    DetailRow(title: "Title", value: title)
                }

                if let firstName = identity.firstName {
                    DetailRow(title: "First Name", value: firstName)
                }

                if let middleName = identity.middleName {
                    DetailRow(title: "Middle Name", value: middleName)
                }

                if let lastName = identity.lastName {
                    DetailRow(title: "Last Name", value: lastName)
                }

                if let username = identity.username {
                    DetailRow(title: "Username", value: username)
                }

                if let company = identity.company {
                    DetailRow(title: "Company", value: company)
                }

                if let ssn = identity.ssn {
                    DetailRow(title: "SSN", value: ssn)
                }

                if let passportNumber = identity.passportNumber {
                    DetailRow(title: "Passport Number", value: passportNumber)
                }

                if let licenseNumber = identity.licenseNumber {
                    DetailRow(title: "License Number", value: licenseNumber)
                }

                if let email = identity.email {
                    DetailRow(title: "Email", value: email)
                }

                if let phone = identity.phone {
                    DetailRow(title: "Phone", value: phone)
                }

                if let address1 = identity.address1 {
                    DetailRow(title: "Address 1", value: address1)
                }

                if let address2 = identity.address2 {
                    DetailRow(title: "Address 2", value: address2)
                }

                if let address3 = identity.address3 {
                    DetailRow(title: "Address 3", value: address3)
                }

                if let postalCode = identity.postalCode {
                    DetailRow(title: "Postal Code", value: postalCode)
                }

                if let city = identity.city {
                    DetailRow(title: "City", value: city)
                }

                if let state = identity.state {
                    DetailRow(title: "State", value: state)
                }

                if let country = identity.country {
                    DetailRow(title: "Country", value: country)
                }
            }
        }
    }

    /// Displays the notes section of the cipher if available
    private var notesInfo: some View {
        Group {
            if let notes = cipher.notes, !notes.isEmpty {
                Text("Notes:").bold()
                Text(notes)
                    .lineLimit(nil)
                    .truncationMode(.tail)
                    .textSelection(.enabled)
            }
        }
    }

    /// Displays custom fields section, supporting both regular and password type fields
    private var customFieldsInfo: some View {
        Group {
            if let fields = cipher.fields, !fields.isEmpty {
                Text("Custom fields:").bold()
                ForEach(fields) { field in
                    if let value = field.value, !value.isEmpty {
                        if field.type == 1 {
                            PasswordRow(title: "Password", password: value)
                        } else {
                            DetailRow(title: field.name, value: value)
                        }
                    }
                }
            }
        }
    }

    /// Displays Time-based One-Time Password (TOTP) information if available
    private var totpInfo: some View {
        Group {
            if let totp = cipher.login?.totp, !totp.isEmpty {
                TotpComponent(totpSecret: totp, copyKeyCode: "t")
            }
        }
    }

    /// Displays attachments section with download functionality
    private var attachmentsInfo: some View {
        Group {
            if let attachments = cipher.attachments, !attachments.isEmpty {
                Text("Attachments:").bold()
                ForEach(attachments) { attachment in
                    GridRow {
                        Text(attachment.fileName ?? "")

                        Button(
                            action: {
                                if let id = attachment.id {
                                    Task {
                                        await cipher.downloadAttachment(id)
                                    }
                                }
                            },
                            label: {
                                Image(systemName: "square.and.arrow.down")
                            }
                        )
                    }
                }
            }
        }
    }
}

/// Extension for Hashable conformance
extension CipherDetailsView {
    /// Implements equality comparison for CipherDetailsView
    /// - Parameters:
    ///   - lhs: Left-hand side CipherDetailsView
    ///   - rhs: Right-hand side CipherDetailsView
    /// - Returns: Boolean indicating if the views are equal
    static func == (lhs: CipherDetailsView, rhs: CipherDetailsView) -> Bool {
        lhs.cipher.id == rhs.cipher.id
    }

    /// Implements hashing for CipherDetailsView
    /// - Parameter hasher: Hasher to use for combining hash values
    func hash(into hasher: inout Hasher) {
        hasher.combine(cipher.id)
    }
}
