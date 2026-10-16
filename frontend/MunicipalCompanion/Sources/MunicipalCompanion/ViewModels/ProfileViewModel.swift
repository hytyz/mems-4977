import Foundation

#if canImport(Combine)
import Combine
#endif

/// Profile screen: shows signed-in user info, handles logout, and edits the
/// API base URL used by the whole app.
@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var baseURLText: String
    @Published var statusMessage: String?
    @Published var isError: Bool = false

    private let auth: AuthManager

    var email: String { auth.auth?.email ?? "" }
    var fullName: String { auth.auth?.fullName ?? "" }
    var isAuthenticated: Bool { auth.isAuthenticated }

    init(auth: AuthManager? = nil) {
        self.auth = auth ?? .shared
        self.baseURLText = AppConfig.apiBaseURL
    }

    func saveBaseURL() {
        let value = baseURLText.trimmed
        guard !value.isEmpty else {
            statusMessage = "The API base URL cannot be empty."
            isError = true
            return
        }
        guard AppConfig.isValidBaseURL(value) else {
            statusMessage = "Enter a valid URL, e.g. http://127.0.0.1:5000"
            isError = true
            return
        }
        AppConfig.apiBaseURL = value
        baseURLText = value
        statusMessage = "API base URL saved."
        isError = false
    }

    func resetBaseURL() {
        baseURLText = AppConfig.defaultBaseURL
        AppConfig.apiBaseURL = AppConfig.defaultBaseURL
        statusMessage = "API base URL reset to the default."
        isError = false
    }

    func logout() {
        auth.signOut()
    }
}
