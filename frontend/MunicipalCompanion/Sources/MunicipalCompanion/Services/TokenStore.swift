import Foundation

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
