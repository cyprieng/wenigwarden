//
//  TextComponents.swift
//  wenigwarden
//
//  Created by Cyprien Guillemot on 19/01/2025.
//

import SwiftUI

/// A view component for displaying bold labels with consistent formatting
struct TextLabel: View {
    /// The label text to display
    private let title: String

    /// Initialize text label
    /// - Parameter title: The label text
    init(title: String) {
        self.title = title
    }

    var body: some View {
        Text("\(title):")
            .bold()
    }
}

/// A view component for displaying truncated text values with consistent width
struct TextValue: View {
    /// The text to display
    private let text: String

    /// Default width for the text value
    private let defaultWidth: CGFloat = 200

    /// Initialize text value
    /// - Parameter text: The text to display
    init(text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(width: defaultWidth, alignment: .leading)
    }
}
