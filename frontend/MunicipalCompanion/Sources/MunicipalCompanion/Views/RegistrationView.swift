import SwiftUI

struct RegistrationView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        Form {
            Section("Create Account") {
                TextField("Full Name", text: $viewModel.fullName)
                    .textContentType(.name)
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
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
                Button {
                    Task { await viewModel.register() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Register")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(!viewModel.isRegisterEnabled)
            }
        }
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
    }
}
