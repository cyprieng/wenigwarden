//
//  2FAInput.swift
//  wenigwarden
//
//  Created by Cyprien Guillemot on 14/01/2025.
//

import SwiftUI

/// OTP digit field
struct OTPDigitField: View {
    /// The text content of the field
    @Binding private var text: String

    /// The index of this field in the OTP sequence
    private let index: Int

    /// Binding to control field focus
    @FocusState.Binding private var focusedField: Int?

    /// Initialize a new OTP digit field
    /// - Parameters:
    ///   - text: Binding to the field's text content
    ///   - index: The position of this field in the OTP sequence
    ///   - focusedField: Binding to control field focus
    init(text: Binding<String>, index: Int, focusedField: FocusState<Int?>.Binding) {
        self._text = text
        self.index = index
        self._focusedField = focusedField
    }

    var body: some View {
        TextField("", text: $text)
            .textFieldStyle(.plain)
            .frame(width: 30, height: 50)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray))
            .multilineTextAlignment(.center)
            .focused($focusedField, equals: index)
            .onReceive(NotificationCenter.default.publisher(for: NSControl.textDidChangeNotification)) { _ in
                // Only allow numbers
                text = text.filter { "0123456789".contains($0) }
            }
    }
}

/// OTP Input
struct OTPInput: View {
    /// Array of OTP digits
    @State private var otpFields: [String] = Array(repeating: "", count: 6)

    /// Currently focused field
    @FocusState private var focusedField: Int?

    /// Callback when OTP is complete
    private let onComplete: (String) -> Void

    /// Number of OTP digits
    private let digitCount = 6

    /// Initialize a new OTP input
    /// - Parameter onComplete: Callback triggered when all digits are entered
    init(onComplete: @escaping (String) -> Void) {
        self.onComplete = onComplete
    }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<6) { index in
                OTPDigitField(
                    text: bindingForIndex(index),
                    index: index,
                    focusedField: $focusedField
                )
            }
        }
        .onAppear {
            focusedField = 0
        }
        .onKeyPress(.init(Character(UnicodeScalar(127)))) {
            handleBackspace()
            return .handled
        }
        .onChange(of: otpFields) { _, newValue in
            if newValue.joined().count == 6 {
                let otp = otpFields.joined()
                onComplete(otp)
            }
        }
    }

    /// Binding for index
    private func bindingForIndex(_ index: Int) -> Binding<String> {
        return Binding(
            get: { otpFields[index] },
            set: { newValue in
                handleInput(newValue: newValue, index: index)
            }
        )
    }

    /// Handle digit input
    private func handleInput(newValue: String, index: Int) {
        // Limit to 1 char
        if newValue.count > 1 {
            otpFields[index] = String(newValue.prefix(1))
        } else {
            otpFields[index] = newValue
        }

        // Go to next field
        if !newValue.isEmpty && index == focusedField && index < 5 {
            focusedField = (focusedField ?? 0) +  1
        }
    }

    /// Handle backspace event
    private func handleBackspace() {
        guard let currentFocus = focusedField else { return }

        if otpFields[currentFocus].isEmpty && currentFocus > 0 {
            // If current field is empty -> go to previous field
            focusedField = currentFocus - 1
            otpFields[currentFocus - 1] = ""
        } else {
            // Clear current field
            otpFields[currentFocus] = ""
        }
    }
}
