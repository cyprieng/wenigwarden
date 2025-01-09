//
//  VaultListViewModel.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 27/08/2024.
//

import Foundation
import SwiftUI

// Default height for the list
let defaultMinHeight: CGFloat = 400

/// ViewModel for managing the list of ciphers
class CipherListViewModel: ObservableObject {
    /// The list of ciphers to display
    @Published var ciphers: [CipherModel]?

    /// The search query entered by the user
    @Published var searchQuery = ""

    /// Min height for the view
    @Published var minHeight: CGFloat? = defaultMinHeight

    /// Navigation path
    @Published var path = NavigationPath()

    /// Currently ocused cipher
    @Published var focusedCipherIndex: Int? = 0

    /// Persistent storage of focused cipher to select it agin when going back
    private static var staticFocusedCipherIndex: Int? = 0

    /// Focus binding for search field
    @Published var isSearchFieldFocused: Bool = false

    /// Persist if we already bound the keyboard events
    private static var isEventAdded = false

    /// Loads the initial list of ciphers when the view appears
    public func loadInitialCiphers() {
        ciphers = Vault.shared.ciphersDecrypted
    }

    /// Performs a search based on the user's query
    /// - Parameter query: The search query entered by the user
    public func performSearch(_ query: String) {
        if query.isEmpty {
            ciphers = Vault.shared.ciphersDecrypted
        } else {
            ciphers = Vault.shared.search(query: query)
        }
    }

    /// Go to cipher details
    public func goToDetails(_ cipher: CipherModel) {
        minHeight = nil
        path.append(CipherDetailsView(cipher: cipher))
    }

    /// When List disappear
    public func onDisappear() {
        minHeight = nil
    }

    /// When list appear
    public func onGoToList() {
        if path.count == 0 {
            minHeight = defaultMinHeight // Reset height
        }
        focusedCipherIndex = CipherListViewModel.staticFocusedCipherIndex  // Reset selected cipher

        // Keyboard shortcuts
        if !CipherListViewModel.isEventAdded {  // Make sure to not bind it twice
            CipherListViewModel.isEventAdded = true
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [self] nsevent in
                if CipherListViewModel.staticFocusedCipherIndex != nil {
                    if nsevent.keyCode == 125 { // arrow down -> move selection dozn
                        CipherListViewModel.staticFocusedCipherIndex = CipherListViewModel.staticFocusedCipherIndex!
                            < ciphers!.count ?
                            CipherListViewModel.staticFocusedCipherIndex! + 1 : 0
                    } else if nsevent.keyCode == 126 { // arrow up -> move selection up
                        CipherListViewModel.staticFocusedCipherIndex = CipherListViewModel.staticFocusedCipherIndex!
                            > 1 ? CipherListViewModel.staticFocusedCipherIndex! - 1 : 0
                    } else if nsevent.keyCode == 36 { // enter -> go to details
                        goToDetails(ciphers![CipherListViewModel.staticFocusedCipherIndex!])
                    } else if nsevent.keyCode == 53 { // escape -> go back
                        if path.count > 0 {
                            path.removeLast()
                        }
                    } else if path.isEmpty {  // Otherwise -> bring back focus to search field if we are on the list
                        isSearchFieldFocused = true
                    }

                    // Set focused cipher
                    focusedCipherIndex = CipherListViewModel.staticFocusedCipherIndex
                }

                return nsevent
            }
        }
    }
}
