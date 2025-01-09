//
//  VaultListItem.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 26/08/2024.
//

import SwiftUI

/// A view representing an item in the list of ciphers
struct CipherListItemView: View {
    @Binding var cipher: CipherModel
    @State private var faviconImage: Image?

    var body: some View {
        HStack {
            faviconImageView
            itemDetails
        }
        .padding(5)
        .onChange(of: cipher.id, initial: true) { _, _  in
            loadFavicon()
        }
    }

    /// View for displaying the favicon image
    private var faviconImageView: some View {
        ZStack {
            // Base globe icon
            Image(systemName: "globe")
                .resizable()
                .foregroundColor(.gray)
                .frame(width: 16, height: 16)

            // Favicon overlay when available
            if let favicon = faviconImage {
                favicon
                    .resizable()
                    .frame(width: 16, height: 16)
                    .transition(.opacity)
            }
        }
        .frame(width: 16, height: 16)
    }

    /// View for displaying the item details (name and username)
    private var itemDetails: some View {
        VStack(alignment: .leading) {
            Text(cipher.name)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(cipher.login?.username ?? "")
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(5)
    }

    /// Loads the favicon image asynchronously
    private func loadFavicon() {
        Task {
            do {
                // Run getFavicon in the background
                let result = await Task.detached(priority: .background) { () -> Image? in
                    return await cipher.getFavicon()
                }.value

                // Update the UI on the main thread
                await MainActor.run {
                    self.faviconImage = result
                }
            }
        }
    }
}
