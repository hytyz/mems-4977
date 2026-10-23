import Foundation

#if canImport(Security)
import Security
#endif

/// Authenticated session persisted between launches.
struct StoredAuth: Codable, Equatable {
    var token: String
    var email: String
    var fullName: String
}

/// Storage abstraction so the persistence mechanism can change without
/// touching AuthManager. The app uses the Keychain (see KeychainTokenStore);
/// UserDefaultsTokenStore exists only for platforms without the Security
/// framework (e.g. Linux type-checking) and is not used on iOS.
protocol TokenStore: AnyObject {
    func save(_ auth: StoredAuth)
    func load() -> StoredAuth?
    func clear()
}

#if canImport(Security)
/// Keychain-backed token storage. The item is only accessible while the
/// device is unlocked (after first unlock) and never migrates to another
/// device.
final class KeychainTokenStore: TokenStore {
    private let service: String
    private let account = "storedAuth"

    init(service: String = "com.polina.municipalcompanion.auth") {
        self.service = service
    }

    func save(_ auth: StoredAuth) {
        guard let data = try? JSONEncoder().encode(auth) else { return }

        // Replace any existing item so a new login always wins.
        clear()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    func load() -> StoredAuth? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data
        else { return nil }

        return try? JSONDecoder().decode(StoredAuth.self, from: data)
    }

    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
#endif

/// Insecure fallback used only where the Keychain is unavailable.
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
