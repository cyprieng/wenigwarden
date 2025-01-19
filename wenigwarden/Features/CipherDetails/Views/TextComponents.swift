//
//  TextComponents.swift
//  wenigwarden
//
//  Created by Cyprien Guillemot on 19/01/2025.
//

import SwiftUI

/// Text label component
struct TextLabel: View {
    let title: String

    var body: some View {
        Text("\(title):")
            .bold()
    }
}

/// Text value component
struct TextValue: View {
    let text: String

    var body: some View {
        Text(text)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(width: 200, alignment: .leading)
    }
}
