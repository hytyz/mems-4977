import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var viewModel: AuthViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

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
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit(signIn)
                }

                if let message = viewModel.errorMessage {
                    Section {
                        ErrorMessageView(message: message)
                    }
                }

                Section {
                    LoadingButton(title: "Sign In", isLoading: viewModel.isLoading, action: signIn)
                    .disabled(!viewModel.isLoginEnabled)

                    NavigationLink("Create an Account") {
                        RegistrationView()
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Municipal Elections")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
        }
    }

    private func signIn() {
        guard viewModel.isLoginEnabled else { return }
        focusedField = nil
        Task { await viewModel.login() }
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let auth = AuthManager.previewSignedOut
        return LoginView(viewModel: AuthViewModel(api: .preview, auth: auth))
            .environmentObject(auth)
    }
}
#endif
