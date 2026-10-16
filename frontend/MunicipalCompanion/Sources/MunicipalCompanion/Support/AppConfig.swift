import Foundation

enum AppConfig {
    static let defaultBaseURL = "http://127.0.0.1:5000"
    private static let baseURLKey = "apiBaseURL"

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
