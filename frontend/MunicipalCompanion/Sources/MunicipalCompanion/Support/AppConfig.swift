import Foundation

/// Build/run-time configuration. A `.env` file is shipped in the app bundle
/// (see `xtool.yml` `resources`) and its `API_BASE_URL` value is synced into
/// UserDefaults (key "apiBaseURL") on each launch, overriding any stale stored
/// value. A value edited on the Profile screen remains effective until the
/// next launch. When no .env file is present, the hardcoded `defaultBaseURL`
/// is the final fallback.
enum AppConfig {
    static let defaultBaseURL = "http://127.0.0.1:5000"
    private static let baseURLKey = "apiBaseURL"

    /// One-time .env application, triggered on first access to `apiBaseURL`.
    private static let envApplied: Void = {
        if let envBaseURL = loadEnvBaseURL(), isValidBaseURL(envBaseURL) {
            UserDefaults.standard.set(envBaseURL, forKey: baseURLKey)
        }
    }()

    static var apiBaseURL: String {
        get {
            _ = envApplied
            return UserDefaults.standard.string(forKey: baseURLKey) ?? defaultBaseURL
        }
        set {
            _ = envApplied
            UserDefaults.standard.set(newValue, forKey: baseURLKey)
        }
    }

    /// Base URL with any trailing slashes removed so paths can be appended.
    static var sanitizedBaseURL: String {
        var value = apiBaseURL.trimmed
        while value.hasSuffix("/") {
            value.removeLast()
        }
        return value
    }

    static func isValidBaseURL(_ value: String) -> Bool {
        guard let url = URL(string: value.trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host != nil
        else { return false }
        return true
    }

    /// Loads API_BASE_URL from the bundled .env file, if present.
    /// `Bundle.main.url(forResource:)` is unreliable for a dotfile with no
    /// extension, so the bundle resource path is joined directly (also trying
    /// the non-dot "env" name).
    private static func loadEnvBaseURL() -> String? {
        guard let resourcePath = Bundle.main.resourcePath else { return nil }
        for name in [".env", "env"] {
            let path = resourcePath + "/" + name
            guard FileManager.default.fileExists(atPath: path),
                  let data = FileManager.default.contents(atPath: path),
                  let text = String(data: data, encoding: .utf8)
            else { continue }
            if let value = parseEnvValue(named: "API_BASE_URL", from: text) {
                return value
            }
        }
        return nil
    }

    /// Minimal .env parsing: skips blank lines and `#` comments, splits on the
    /// first `=`, and trims whitespace and matching quotes from key and value.
    private static func parseEnvValue(named key: String, from text: String) -> String? {
        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmed
            guard !line.isEmpty, !line.hasPrefix("#"),
                  let equalsIndex = line.firstIndex(of: "=")
            else { continue }
            let keyPart = unquoted(String(line[..<equalsIndex]).trimmed)
            guard keyPart == key else { continue }
            let value = unquoted(String(line[line.index(after: equalsIndex)...]).trimmed)
            return value.isEmpty ? nil : value
        }
        return nil
    }

    private static func unquoted(_ value: String) -> String {
        var result = value
        if result.count >= 2,
           (result.hasPrefix("\"") && result.hasSuffix("\"")) ||
           (result.hasPrefix("'") && result.hasSuffix("'")) {
            result.removeFirst()
            result.removeLast()
        }
        return result
    }
}
