//
//  ClipboardButtonView.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 26/08/2024.
//

import SwiftUI

/// A view that presents a button to copy data to the clipboard
struct ClipboardButton: View {
    /// The data to be copied to the clipboard
    private let data: String

    /// The copy keycode shortcuts
    private let copyKeyCode: String?

    /// Indicates whether the copied icon should be shown
    @State private var showCopiedIcon: Bool = false

    /// Show the copy keycode
    @State private var showCopyKeyCode: Bool = false

    /// Store monitor
    @State private var keyListener: Any?
    @State private var cmdListener: Any?

    /// Initialize a new ClipboardButton
    /// - Parameters:
    ///   - data: The string to be copied to clipboard
    ///   - copyKeyCode: Optional keyboard shortcut key
    init(data: String, copyKeyCode: String? = nil) {
        self.data = data
        self.copyKeyCode = copyKeyCode
    }

    var body: some View {
        Button(action: {
            copyToClipboard(data)
        }, label: {
            ZStack {
                if showCopyKeyCode {
                    // Show keycode
                    Text("\(copyKeyCode?.uppercased() ?? "")")
                } else {
                    // Show appropriate icon based on the copied state
                    Image(systemName: showCopiedIcon ? "checkmark.circle" : "clipboard")
                        .foregroundColor(showCopiedIcon ? .green : .primary)
                        .frame(alignment: .center)
                }
            }.frame(width: 16, height: 16)
        })
        .onAppear {
            if copyKeyCode != nil {
                // Copy with CMD+copyKeyCode
                keyListener = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [self] nsevent in
                    if nsevent.modifierFlags.contains(.command) {
                        if nsevent.characters == copyKeyCode {
                            copyToClipboard(data)
                            showCopyKeyCode = false
                            return nil
                        }
                    }

                    return nsevent
                }

                // CMD show copyKeycode
                cmdListener = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { nsevent in
                    if nsevent.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command {
                        showCopyKeyCode = true
                    } else {
                        showCopyKeyCode = false
                    }

                    return nsevent
                }
            }
        }
        .onDisappear {
            // Remove monitor
            if let monitor = self.keyListener {
                NSEvent.removeMonitor(monitor)
            }
            if let monitor = self.cmdListener {
                NSEvent.removeMonitor(monitor)
            }
        }
    }

    /// Copies the given string to the system clipboard
    /// - Parameter data: The string to be copied to the clipboard
    private func copyToClipboard(_ data: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(data, forType: .string)

        // Show copied icon
        showCopiedIcon = true

        // Reset the copied state after a 2-second delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedIcon = false
        }
    }
}
