import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var viewModel: AuthViewModel

    init() {
        _viewModel = StateObject(wrappedValue: AuthViewModel())
    }

    init(viewModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                if let notice = authManager.sessionNotice {
                    Section {
                        Label(notice, systemImage: "clock.badge.exclamationmark")
                            .font(.footnote)
                            .foregroundColor(.orange)
                    }
                }

                Section("Sign In") {
                    EmailField(text: $viewModel.email)
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                }

                if let message = viewModel.errorMessage {
                    Section {
                        ErrorMessageView(message: message)
                    }
                }

                Section {
                    LoadingButton(title: "Sign In", isLoading: viewModel.isLoading) {
                        Task { await viewModel.login() }
                    }
                    .disabled(!viewModel.isLoginEnabled)

                    NavigationLink("Create an Account") {
                        RegistrationView()
                    }
                }
            }
            .navigationTitle("Municipal Elections")
        }
    }
}
