//
//  VaultListViewModel.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 27/08/2024.
//

import Foundation
import SwiftUI
import Combine

/// Default height for the cipher list view
private let defaultMinHeight: CGFloat = 400

/// ViewModel for managing the list of vault ciphers and related UI state
final class CipherListViewModel: ObservableObject {
    /// The filtered list of ciphers to display
    @Published private(set) var ciphers: [CipherModel]?

    /// The current search query
    @Published var searchQuery = ""

    /// Minimum height for the view
    @Published var minHeight: CGFloat? = defaultMinHeight

    /// Navigation stack path
    @Published var path = NavigationPath()

    /// Index of the currently focused cipher
    @Published var focusedCipherIndex: Int? = 0

    /// Focus state for the search field
    @Published var isSearchFieldFocused: Bool = false

    /// Persisted focused cipher index across view updates
    internal static var staticFocusedCipherIndex: Int? = 0

    /// Flag to prevent multiple keyboard event bindings
    private static var eventMonitor: Any?

    /// Last sync date
    private var lastSyncDate: Date?

    /// Initialize the view model and set up keyboard shortcuts
    init() {
        lastSyncDate = Date()
    }

    /// Sets up keyboard shortcuts for navigation and actions
    private func setupKeyboardShortcuts() {
        if let monitor = CipherListViewModel.eventMonitor {
            NSEvent.removeMonitor(monitor)
            CipherListViewModel.eventMonitor = nil
        }

        NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self,
                  let focusedIndex = CipherListViewModel.staticFocusedCipherIndex else {
                return event
            }

            return self.handleKeyboardEvent(event, focusedIndex: focusedIndex)
        }
    }

    /// Handles keyboard events for navigation and actions
    /// - Parameters:
    ///   - event: The keyboard event
    ///   - focusedIndex: Currently focused cipher index
    /// - Returns: The event if it should be processed further, nil if handled
    private func handleKeyboardEvent(_ event: NSEvent, focusedIndex: Int) -> NSEvent? {
        if path.isEmpty {
            return handleListViewKeyboardEvent(event, focusedIndex: focusedIndex)
        } else {
            return handleDetailViewKeyboardEvent(event)
        }
    }

    /// Handles keyboard events when in list view
    private func handleListViewKeyboardEvent(_ event: NSEvent, focusedIndex: Int) -> NSEvent? {
        guard let ciphers = ciphers else { return event }

        switch event.keyCode {
        case 125: // Down arrow
            CipherListViewModel.staticFocusedCipherIndex = (focusedIndex < ciphers.count) ?
                focusedIndex + 1 : 0

        case 126: // Up arrow
            CipherListViewModel.staticFocusedCipherIndex = (focusedIndex > 1) ?
                focusedIndex - 1 : 0

        case 36: // Enter
            if ciphers.count > focusedIndex {
                goToDetails(ciphers[focusedIndex], index: focusedIndex)
            }

        case 53: // Escape
            AppState.shared.toggleAppVisibility()

        default:
            if !isSearchFieldFocused {
                isSearchFieldFocused = true
            } else {
                return event
            }
        }

        focusedCipherIndex = CipherListViewModel.staticFocusedCipherIndex
        return nil
    }

    /// Handles keyboard events when in detail view
    private func handleDetailViewKeyboardEvent(_ event: NSEvent) -> NSEvent? {
        if event.keyCode == 53 { // Escape
            path.removeLast()
            return nil
        }
        return event
    }

    /// Loads the initial list of ciphers
    @MainActor
    func loadInitialCiphers() {
        performSearch(searchQuery)
    }

    /// Performs a search based on the query
    /// - Parameter query: The search query
    func performSearch(_ query: String) {
        ciphers = query.isEmpty ?
            Vault.shared.ciphersDecrypted :
            Vault.shared.search(query: query)
    }

    /// Navigates to cipher details
    /// - Parameters:
    ///   - cipher: The cipher to display
    ///   - index: Index of the cipher in the list
    func goToDetails(_ cipher: CipherModel, index: Int) {
        minHeight = nil
        CipherListViewModel.staticFocusedCipherIndex = index
        focusedCipherIndex = index
        path.append(CipherDetailsView(cipher: cipher))
    }

    /// Navigates to settings view
    func goToSettings() {
        minHeight = nil
        path.append(SettingsView(refreshList: { [weak self] in
            Task { [weak self] in
                await self?.loadInitialCiphers()
            }
        }))
    }

    /// Vault synchronization
    func sync() {
        if lastSyncDate == nil || Date().timeIntervalSince(lastSyncDate!) > 900 {
            lastSyncDate = Date()
            Task {
                try await Vault.shared.updateVault()
                await self.loadInitialCiphers()
            }
        }
    }

    /// Handles view appearance
    func onAppear() {
        if path.isEmpty {
            minHeight = defaultMinHeight
            self.sync()
        }
        focusedCipherIndex = CipherListViewModel.staticFocusedCipherIndex
        setupKeyboardShortcuts()
    }
}
