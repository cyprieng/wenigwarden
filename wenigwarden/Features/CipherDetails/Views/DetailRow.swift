//
//  DetailRow.swift
//  wenigwarden
//
//  Created by Cyprien Guillemot on 19/01/2025.
//

import SwiftUI

/// A view component to display a labeled detail with copy functionality
struct DetailRow: View {
    /// The label or title for the detail
    private let title: String

    /// The value to display
    private let value: String

    /// Optional keyboard shortcut for copying the value
    private let copyKeyCode: String?

    /// Initialize detail row
    /// - Parameters:
    ///   - title: The label for the detail
    ///   - value: The value to display
    ///   - copyKeyCode: Optional keyboard shortcut for copying
    init(
        title: String,
        value: String,
        copyKeyCode: String? = nil
    ) {
        self.title = title
        self.value = value
        self.copyKeyCode = copyKeyCode
    }

    var body: some View {
        GridRow {
            TextLabel(title: title)

            TextValue(text: value)

            ClipboardButton(
                data: value,
                copyKeyCode: copyKeyCode
            )
        }
    }
}
