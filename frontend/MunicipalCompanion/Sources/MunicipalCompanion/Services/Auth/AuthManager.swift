import Foundation

#if canImport(Combine)
import Combine
#endif

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var auth: StoredAuth?
    @Published var sessionNotice: String?

    private let store: TokenStore

    init(store: TokenStore? = nil) {
        let resolved = store ?? Self.defaultStore()
        self.store = resolved
        self.auth = resolved.load()
        ApiService.shared.setToken(auth?.token)
        validateSession()
    }

    private static func defaultStore() -> TokenStore {
        #if canImport(Security)
        return KeychainTokenStore()
        #else
        return UserDefaultsTokenStore()
        #endif
    }

    var isAuthenticated: Bool { auth != nil }
    var displayName: String { auth?.fullName ?? "Guest" }

    var userID: String? {
        guard let token = auth?.token else { return nil }
        return JWTClaims(token: token)?.subject
    }

    func signIn(_ response: AuthResponse) {
        let stored = StoredAuth(token: response.token, email: response.email, fullName: response.fullName)
        sessionNotice = nil
        auth = stored
        store.save(stored)
        ApiService.shared.setToken(stored.token)
    }

    func signOut() {
        auth = nil
        store.clear()
        ApiService.shared.setToken(nil)
    }

    func expireSession() {
        guard isAuthenticated else { return }
        signOut()
        sessionNotice = "Your session has expired. Please sign in again."
    }

    func validateSession() {
        guard let token = auth?.token,
              let claims = JWTClaims(token: token),
              claims.isExpired()
        else { return }
        expireSession()
    }
}
