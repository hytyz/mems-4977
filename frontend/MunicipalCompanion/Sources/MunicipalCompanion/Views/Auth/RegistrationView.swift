import SwiftUI

struct RegistrationView: View {
    @StateObject private var viewModel: AuthViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case fullName
        case email
        case password
        case confirmPassword
    }

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
                    .focused($focusedField, equals: .fullName)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .email }
                EmailField(text: $viewModel.email)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
                SecureField("Password (min 6 characters)", text: $viewModel.password)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .confirmPassword }
                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .confirmPassword)
                    .submitLabel(.join)
                    .onSubmit(register)
            }

            if let message = viewModel.errorMessage {
                Section {
                    ErrorMessageView(message: message)
                }
            }

            Section {
                LoadingButton(title: "Register", isLoading: viewModel.isLoading, action: register)
                .disabled(!viewModel.isRegisterEnabled)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }

    private func register() {
        guard viewModel.isRegisterEnabled else { return }
        focusedField = nil
        Task { await viewModel.register() }
    }
}

#if DEBUG
struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RegistrationView(viewModel: AuthViewModel(api: .preview, auth: AuthManager.previewSignedOut))
        }
    }
}
#endif
