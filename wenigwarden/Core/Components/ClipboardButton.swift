//
//  ClipboardButtonView.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 26/08/2024.
//

import SwiftUI

/// Copies the given string to the system clipboard
/// - Parameter data: The string to be copied to the clipboard
func copyToClipboard(_ data: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(data, forType: .string)
}

/// A view that presents a button to copy data to the clipboard
struct ClipboardButton: View {
    /// The data to be copied to the clipboard
    let data: String

    /// Indicates whether the copied icon should be shown
    @State private var showCopiedIcon: Bool = false

    var body: some View {
        Button(action: {
            // Copy data to clipboard
            copyToClipboard(data)
            // Show copied icon
            showCopiedIcon = true

            // Reset the copied state after a 2-second delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showCopiedIcon = false
            }
        }, label: {
            // Show appropriate icon based on the copied state
            Image(systemName: showCopiedIcon ? "checkmark.circle" : "clipboard")
                .foregroundColor(showCopiedIcon ? .green : .primary)
        })
        // Show appropriate help text based on the copied state
        .help(showCopiedIcon ? "Copied!" : "Copy to clipboard")
    }
}
