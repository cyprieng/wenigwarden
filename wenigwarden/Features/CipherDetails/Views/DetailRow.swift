//
//  DetailRow.swift
//  wenigwarden
//
//  Created by Cyprien Guillemot on 19/01/2025.
//

import SwiftUI

/// Component for a text: value with a copy button
struct DetailRow: View {
    let title: String
    let value: String
    let copyKeyCode: String?

    var body: some View {
        GridRow {
            TextLabel(title: title)

            TextValue(text: value)

            ClipboardButton(data: value, copyKeyCode: copyKeyCode)
        }
    }
}
