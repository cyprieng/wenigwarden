//
//  UriRow.swift
//  wenigwarden
//
//  Created by Cyprien Guillemot on 19/01/2025.
//

import SwiftUI

/// A row displaying the URI with a clickable link
/// A view component to display a URI with link and copy functionality
struct UriRow: View {
    /// The URI to display and interact with
    private let uri: String

    /// Optional keyboard shortcut for copying the URI
    private let copyKeyCode: String?

    /// Initialize URI row
    /// - Parameters:
    ///   - uri: The URI to display
    ///   - copyKeyCode: Optional keyboard shortcut for copying
    init(uri: String, copyKeyCode: String? = nil) {
        self.uri = uri
        self.copyKeyCode = copyKeyCode
    }

    var body: some View {
        GridRow {
            TextLabel(title: "URI")

            uriLink

            ClipboardButton(
                data: uri,
                copyKeyCode: copyKeyCode
            )
        }
    }

    /// Link view for the URI with hover effects
    private var uriLink: some View {
        Link(destination: makeURL()) {
            TextValue(text: uri)
        }
        .onHover { isHovered in
            if isHovered {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }

    /// Creates a URL from the URI string with fallback
    /// - Returns: Valid URL, defaulting to https:// if invalid
    private func makeURL() -> URL {
        URL(string: uri) ?? URL(string: "https://")!
    }
}
