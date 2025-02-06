//
//  PasswordRow.swift
//  wenigwarden
//
//  Created by Cyprien Guillemot on 19/01/2025.
//

import SwiftUI

/// A view component for displaying a password field with visibility toggle and copy functionality
struct PasswordRow: View {
    /// The label for the password field
    private let title: String

    /// The password value
    private let password: String

    /// Optional keyboard shortcut for copying
    private let copyKeyCode: String?

    /// Controls password visibility state
    @State private var isPasswordVisible: Bool = false

    /// Initialize password row
    /// - Parameters:
    ///   - title: The label for the password field
    ///   - password: The password value
    ///   - copyKeyCode: Optional keyboard shortcut for copying
    init(
        title: String,
        password: String,
        copyKeyCode: String? = nil
    ) {
        self.title = title
        self.password = password
        self.copyKeyCode = copyKeyCode
    }

    var body: some View {
        GridRow {
            TextLabel(title: title)

            passwordText

            actionButtons
        }
    }

    /// Password text display with masking
    private var passwordText: some View {
        TextValue(
            text: isPasswordVisible ? password : maskPassword()
        )
    }

    /// Action buttons for copy and visibility toggle
    private var actionButtons: some View {
        HStack {
            visibilityToggle

            ClipboardButton(
                data: password,
                copyKeyCode: copyKeyCode
            ).gridColumnAlignment(.trailing)
        }
    }

    /// Button to toggle password visibility
    private var visibilityToggle: some View {
        Button(
            action: { isPasswordVisible.toggle() },
            label: {
                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
            }
        )
    }

    /// Creates a masked version of the password
    /// - Returns: String of bullet characters
    private func maskPassword() -> String {
        String(repeating: "•", count: 8)
    }
}
