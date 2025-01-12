//
//  LoginScreen.swift
//  Wenigwarden
//
//  Created by Cyprien Guillemot on 19/08/2024.
//

import SwiftUI

/// The login screen view
struct LoginView: View {
    @StateObject var viewModel: LoginViewModel = LoginViewModel()

    var body: some View {
        VStack(spacing: 20) {
            loginForm
            signInButton
        }
        .onAppear(perform: viewModel.loadInitialValues)
    }

    /// The login form view
    private var loginForm: some View {
        Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 15) {
            formRow(label: "URL", field: urlField)
            formRow(label: "Email", field: emailField)
            formRow(label: "Password", field: passwordField)
        }
    }

    /// A function to create a form row with a label and a field
    /// - Parameters:
    ///   - label: The label text
    ///   - field: The field view
    /// - Returns: A view representing a form row
    private func formRow<Content: View>(label: String, field: Content) -> some View {
        GridRow {
            Text(label)
                .frame(width: 80, alignment: .leading)
            field
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit(viewModel.submitForm)
                .frame(alignment: .leading)
        }
    }

    /// The URL text field
    private var urlField: some View {
        TextField("Enter URL", text: $viewModel.url)
    }

    /// The email text field
    private var emailField: some View {
        TextField("Enter Email", text: $viewModel.email)
    }

    /// The password secure field
    private var passwordField: some View {
        SecureField("Enter Password", text: $viewModel.password)
    }

    /// The sign-in button
    private var signInButton: some View {
        ButtonWithLoader(action: viewModel.submitForm, label: {
            Label("Sign In", systemImage: "lock.open")
                .frame(minWidth: 100, minHeight: 30)
        }, isLoading: $viewModel.isLoading, error: $viewModel.error)
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.isFormValid)
    }
}
