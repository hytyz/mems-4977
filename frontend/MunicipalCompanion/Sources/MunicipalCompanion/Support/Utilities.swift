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
    if let localized = error as? LocalizedError, let description = localized.errorDescription {
        return description
    }
    return error.localizedDescription
}

func isCancellation(_ error: Error) -> Bool {
    switch error {
    case is CancellationError: return true
    case let apiError as ApiError: return apiError.isCancellation
    case let firebaseError as FirebaseServiceError: return firebaseError == .cancelled
    default: return false
    }
}
