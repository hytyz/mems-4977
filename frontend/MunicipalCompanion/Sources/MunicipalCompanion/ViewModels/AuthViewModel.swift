import Foundation

#if canImport(Combine)
import Combine
#endif

/// Handles login and registration, including client-side validation
/// (required fields, email format, password length).
@MainActor
final class AuthViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: ApiService
    private let auth: AuthManager

    init(api: ApiService = .shared, auth: AuthManager? = nil) {
        self.api = api
        self.auth = auth ?? .shared
    }

    var isLoginEnabled: Bool {
        !email.trimmed.isEmpty && !password.isEmpty && !isLoading
    }

    var isRegisterEnabled: Bool {
        !fullName.trimmed.isEmpty && !email.trimmed.isEmpty
            && !password.isEmpty && !confirmPassword.isEmpty && !isLoading
    }

    func login() async {
        guard validateLogin() else { return }
        await perform { [self] in
            let response = try await api.login(LoginRequest(email: email.trimmed, password: password))
            auth.signIn(response)
        }
    }

    func register() async {
        guard validateRegistration() else { return }
        await perform { [self] in
            let response = try await api.register(
                RegisterRequest(fullName: fullName.trimmed, email: email.trimmed, password: password)
            )
            auth.signIn(response)
        }
    }

    private func perform(_ action: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await action()
        } catch {
            if !((error as? ApiError)?.isCancellation ?? false) {
                errorMessage = userMessage(for: error)
            }
        }
    }

    private func validateLogin() -> Bool {
        if email.trimmed.isEmpty {
            errorMessage = "Please enter your email."
            return false
        }
        if !isValidEmail(email.trimmed) {
            errorMessage = "Please enter a valid email address."
            return false
        }
        if password.isEmpty {
            errorMessage = "Please enter your password."
            return false
        }
        errorMessage = nil
        return true
    }

    private func validateRegistration() -> Bool {
        if fullName.trimmed.isEmpty {
            errorMessage = "Please enter your full name."
            return false
        }
        if !isValidEmail(email.trimmed) {
            errorMessage = "Please enter a valid email address."
            return false
        }
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters."
            return false
        }
        if password != confirmPassword {
            errorMessage = "Passwords do not match."
            return false
        }
        errorMessage = nil
        return true
    }

    private func isValidEmail(_ value: String) -> Bool {
        // Simple pragmatic check; the server re-validates anyway.
        let pattern = #"^\S+@\S+\.\S+$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }
}
