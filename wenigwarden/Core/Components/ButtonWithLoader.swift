//
//  ButtonWithLoader.swift
//  wenigwarden
//
//  Created by Cyprien Guillemot on 11/01/2025.
//

import SwiftUI

// Button with loader animation
struct ButtonWithLoader<Label>: View where Label: View {
    /// Action executed on button click
    private let action: () -> Void

    /// Button label view builder
    private let label: () -> Label

    /// Loading state of the button
    @Binding private var isLoading: Bool

    /// Error state flag
    @Binding private var error: Bool

    /// Internal state for shake animation
    @State private var shakeButton: Bool = false

    /// Initialize a new ButtonWithLoader
    /// - Parameters:
    ///   - action: The action to perform when clicked
    ///   - isLoading: Binding to control the loading state
    ///   - error: Binding to control the error state
    ///   - label: ViewBuilder for the button's label
    init(
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label,
        isLoading: Binding<Bool>,
        error: Binding<Bool>
    ) {
        self.action = action
        self.label = label
        self._isLoading = isLoading
        self._error = error
    }

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
