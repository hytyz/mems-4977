import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Sign In") {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                }

                if let message = viewModel.errorMessage {
                    Section {
                        ErrorMessageView(message: message)
                    }
                }

                Section {
                    Button {
                        Task { await viewModel.login() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!viewModel.isLoginEnabled)

                    NavigationLink {
                        RegistrationView()
                    } label: {
                        Text("Create an Account")
                    }
                }
            }
            .navigationTitle("Municipal Companion")
        }
    }
}
