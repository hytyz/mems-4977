import Foundation

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

func mediaURL(from urlString: String?) -> URL? {
    guard let trimmed = urlString?.trimmed, !trimmed.isEmpty else { return nil }
    if let url = URL(string: trimmed),
       let scheme = url.scheme?.lowercased(),
       scheme == "http" || scheme == "https" {
        return url
    }
    let path = trimmed.hasPrefix("/") ? String(trimmed.dropFirst()) : trimmed
    return URL(string: AppConfig.sanitizedBaseURL + "/" + path)
}

func userMessage(for error: Error) -> String {
    (error as? ApiError)?.errorDescription ?? error.localizedDescription
}
