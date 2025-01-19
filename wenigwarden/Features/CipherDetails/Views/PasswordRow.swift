//
//  PasswordRow.swift
//  wenigwarden
//
//  Created by Cyprien Guillemot on 19/01/2025.
//

import SwiftUI

/// Password row component
struct PasswordRow: View {
    let password: String
    let copyKeyCode: String?

    @State private var isPasswordVisible: Bool = false

    var body: some View {
        GridRow {
            TextLabel(title: "Password")

            TextValue(text: isPasswordVisible ? password : String(repeating: "•", count: 8))

            HStack {
                ClipboardButton(data: password, copyKeyCode: copyKeyCode)

                Button(action: { isPasswordVisible.toggle() }, label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                })
            }
        }
    }
}
