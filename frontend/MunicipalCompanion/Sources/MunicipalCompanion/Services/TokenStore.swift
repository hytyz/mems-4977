import Foundation

/// Authenticated session persisted between launches.
struct StoredAuth: Codable, Equatable {
    var token: String
    var email: String
    var fullName: String
}

/// Small storage abstraction so the token store can be swapped for a
/// Keychain-backed implementation later without touching AuthManager.
/// NOTE: UserDefaults is NOT secure storage; a production app should use the
/// Keychain. It is used here because the Linux build has no Keychain.
protocol TokenStore: AnyObject {
    func save(_ auth: StoredAuth)
    func load() -> StoredAuth?
    func clear()
}

final class UserDefaultsTokenStore: TokenStore {
    private let defaults: UserDefaults
    private let key = "municipalCompanion.storedAuth"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(_ auth: StoredAuth) {
        if let data = try? JSONEncoder().encode(auth) {
            defaults.set(data, forKey: key)
        }
    }

    func load() -> StoredAuth? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(StoredAuth.self, from: data)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
