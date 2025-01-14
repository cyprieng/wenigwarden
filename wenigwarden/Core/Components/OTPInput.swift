//
//  2FAInput.swift
//  wenigwarden
//
//  Created by Cyprien Guillemot on 14/01/2025.
//

import SwiftUI

// Button with loader animation
struct ButtonWithLoader<Label>: View where Label: View {
    // Action on click
    let action: () -> Void

    // Label
    let label: () -> Label

    // Is loading state
    @Binding var isLoading: Bool

    // Error flag
    @Binding var error: Bool

    // Shake button when there is an error
    @State var shakeButton: Bool = false

    var body: some View {
        if isLoading {
            // Button with loader
            Button(action: {}, label: {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.7)
                    .frame(minWidth: 100, minHeight: 30)

            })
            .disabled(true)
        } else {
            // Classic button
            Button(action: action, label: label)
                .modifier(ShakeEffect(shakes: shakeButton ? 2 : 0))
                .animation(.default, value: shakeButton)
                .onChange(of: error, initial: true, {
                    // In case error is true -> shake the button
                    if error {
                        Task {
                            shakeButton = true
                            try? await Task.sleep(for: .milliseconds(250))
                            shakeButton = false
                            error = false
                        }
                    }
                })
        }
    }
}
