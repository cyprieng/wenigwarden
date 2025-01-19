//
//  UriRow.swift
//  wenigwarden
//
//  Created by Cyprien Guillemot on 19/01/2025.
//

import SwiftUI

/// A row displaying the URI with a clickable link
struct UriRow: View {
    let uri: String
    let copyKeyCode: String?

    var body: some View {
        GridRow {
            TextLabel(title: "URI")

            Link(destination: URL(string: uri) ?? URL(string: "https://")!) {
                TextValue(text: uri)
            }
            .onHover { _ in
                NSCursor.pointingHand.set()
            }

            ClipboardButton(data: uri, copyKeyCode: copyKeyCode)
        }
    }
}
