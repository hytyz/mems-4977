import SwiftUI

struct RegistrationView: View {
    @StateObject private var viewModel: AuthViewModel

    init() {
        _viewModel = StateObject(wrappedValue: AuthViewModel())
    }

    init(viewModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section("Create Account") {
                TextField("Full Name", text: $viewModel.fullName)
                    .textContentType(.name)
                EmailField(text: $viewModel.email)
                SecureField("Password (min 6 characters)", text: $viewModel.password)
                    .textContentType(.newPassword)
                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                    .textContentType(.newPassword)
            }

            if let message = viewModel.errorMessage {
                Section {
                    ErrorMessageView(message: message)
                }
            }

            Section {
                LoadingButton(title: "Register", isLoading: viewModel.isLoading) {
                    Task { await viewModel.register() }
                }
                .disabled(!viewModel.isRegisterEnabled)
            }
        }
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
    }
}
