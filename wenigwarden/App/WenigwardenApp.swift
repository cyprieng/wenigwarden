//
//  WenigwardenApp.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 19/08/2024.
//

import SwiftUI

@main
struct WenigwardenApp: App {
    var body: some Scene {
        // Declares a menu bar extra with a title and system image
        MenuBarExtra("Wenigwarden", systemImage: "key.fill") {
            // The content of the menu bar extra
            HomeView()
        }
        // Sets the style of the menu bar extra
        .menuBarExtraStyle(.window)
    }
}
