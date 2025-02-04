//
//  VaultListItem.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 26/08/2024.
//

import SwiftUI

/// A view representing an item in the list of ciphers
/// A view that displays a single cipher item in the list
struct CipherListItemView: View {
    /// The cipher model to display
    @Binding var cipher: CipherModel

    /// The favicon image for the cipher
    @State private var faviconImage: Image?

    /// Callback for navigating to details view
    private let goToDetails: () -> Void

    /// Initialize the cipher list item view
    /// - Parameters:
    ///   - cipher: Binding to the cipher model
    ///   - goToDetails: Callback for navigation
    init(cipher: Binding<CipherModel>, goToDetails: @escaping () -> Void) {
        self._cipher = cipher
        self.goToDetails = goToDetails
    }

    var body: some View {
        HStack {
            faviconImageView
            itemDetails
            Spacer()
            detailsButton
        }
        .padding(5)
        .onChange(of: cipher.id, initial: true) { _, _ in
            loadFavicon()
        }
    }

    /// View for displaying the favicon image
    private var faviconImageView: some View {
        ZStack {
            defaultIcon
            faviconOverlay
        }
        .frame(width: 16, height: 16)
    }

    /// Default icon based on cipher type
    private var defaultIcon: some View {
        Image(systemName: getDefaultImage())
            .resizable()
            .scaledToFit()
            .foregroundColor(.gray)
            .frame(width: 16, height: 16)
    }

    /// Favicon overlay when available
    private var faviconOverlay: some View {
        Group {
            if let favicon = faviconImage {
                favicon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .transition(.opacity)
            }
        }
    }

    /// View for displaying item details
    private var itemDetails: some View {
        VStack(alignment: .leading) {
            Text(cipher.name)
                .lineLimit(1)
                .truncationMode(.tail)

            secondaryText
        }
        .padding(5)
    }

    /// Secondary text based on cipher type
    private var secondaryText: some View {
        Group {
            switch cipher.type {
            case .creditCard: // Card
                Text("*\(cipher.card?.number?.suffix(4) ?? "")")
            case .identity: // Identity
                Text("\(cipher.identity?.firstName ?? "") \(cipher.identity?.lastName ?? "")")
            default: // Login or other
                Text("\(cipher.login?.username ?? "")")
            }
        }
        .lineLimit(1)
        .truncationMode(.tail)
    }

    /// Details button
    private var detailsButton: some View {
        Button(action: goToDetails) {
            Image(systemName: "note.text")
        }
    }

    /// Get default image name based on cipher type
    private func getDefaultImage() -> String {
        switch cipher.type {
        case .creditCard:
            return "creditcard"
        case .identity:
            return "person.text.rectangle"
        case .note:
            return "document"
        default:
            return "globe"
        }
    }

    /// Loads the favicon image asynchronously
    private func loadFavicon() {
        Task {
            let result = await Task.detached(priority: .background) {
                await cipher.getFavicon()
            }.value

            await MainActor.run {
                self.faviconImage = result
            }
        }
    }
}
