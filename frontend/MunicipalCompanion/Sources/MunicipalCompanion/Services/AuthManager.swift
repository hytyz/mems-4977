import Foundation

#if canImport(Combine)
import Combine
#endif

/// Singleton-ish session manager. Persists token/email/fullName in the
/// Keychain (see KeychainTokenStore) and keeps the shared ApiService's bearer
/// token in sync.
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var auth: StoredAuth?

    private let store: TokenStore

    init(store: TokenStore? = nil) {
        let resolved = store ?? Self.defaultStore()
        self.store = resolved
        self.auth = resolved.load()
        ApiService.shared.setToken(auth?.token)
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

    func signIn(_ response: AuthResponse) {
        let stored = StoredAuth(token: response.token, email: response.email, fullName: response.fullName)
        auth = stored
        store.save(stored)
        ApiService.shared.setToken(stored.token)
    }

    func signOut() {
        auth = nil
        store.clear()
        ApiService.shared.setToken(nil)
    }
}
