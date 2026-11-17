import Foundation

#if canImport(Security)
import Security
#endif

struct StoredAuth: Codable, Equatable {
    var token: String
    var email: String
    var fullName: String
}

protocol TokenStore: AnyObject {
    func save(_ auth: StoredAuth)
    func load() -> StoredAuth?
    func clear()
}

#if canImport(Security)
final class KeychainTokenStore: TokenStore {
    private let service: String
    private let account = "storedAuth"

    init(service: String = "com.polina.municipalcompanion.auth") {
        self.service = service
    }

    func save(_ auth: StoredAuth) {
        guard let data = try? JSONEncoder().encode(auth) else { return }

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
