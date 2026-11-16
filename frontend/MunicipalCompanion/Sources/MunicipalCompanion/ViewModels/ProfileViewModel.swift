import Foundation

#if canImport(Combine)
import Combine
#endif

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var baseURLText: String
    @Published var statusMessage: String?
    @Published var isError: Bool = false

    private let auth: AuthManager

    var email: String { auth.auth?.email ?? "" }
    var fullName: String { auth.auth?.fullName ?? "" }

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
            statusMessage = "Enter a valid URL, e.g. https://example.azurewebsites.net"
            isError = true
            return
        }
        AppConfig.apiBaseURL = value
        baseURLText = value
        statusMessage = "API base URL saved."
        isError = false
    }

    func resetBaseURL() {
        let shipped = AppConfig.shippedBaseURL
        baseURLText = shipped
        AppConfig.apiBaseURL = shipped
        statusMessage = "API base URL reset to the default."
        isError = false
    }
}
