import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Typed errors surfaced to the UI with meaningful, user-friendly text.
enum ApiError: LocalizedError {
    case invalidURL
    case invalidResponse
    case encoding(underlying: Error)
    case decoding(underlying: Error)
    case transport(underlying: Error)
    case http(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The API address is invalid. Check the base URL on the Profile tab."
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .encoding(let underlying):
            return "Could not build the request. \(underlying.localizedDescription)"
        case .decoding(let underlying):
            return "Could not read the server response. \(underlying.localizedDescription)"
        case .transport(let underlying):
            let detail = (underlying as? URLError)?.localizedDescription ?? underlying.localizedDescription
            return "Network error: \(detail)"
        case .http(let statusCode, let message):
            let base: String
            switch statusCode {
            case 400:
                base = "The request was rejected (400)."
            case 401:
                base = "Your session is missing or expired (401). Please sign in again."
            case 404:
                base = "The requested item was not found (404)."
            case 409:
                base = "That item already exists (409)."
            case 500...599:
                base = "The server had a problem (500)."
            default:
                base = "The request failed with status \(statusCode)."
            }
            if let message, !message.isEmpty {
                return "\(base) \(message)"
            }
            return base
        }
    }

    var isCancellation: Bool {
        switch self {
        case .transport(let underlying):
            if underlying is CancellationError { return true }
            if let urlError = underlying as? URLError, urlError.code == .cancelled { return true }
            return false
        default:
            return false
        }
    }

    /// Extracts a readable message from common server error body shapes:
    /// {"message": "..."}, {"error": "..."}, {"title": "..."} (ProblemDetails),
    /// {"errors": {"Field": ["..."]}} (ASP.NET validation), or plain text.
    static func serverMessage(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        if let object = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] {
            for key in ["message", "error", "title", "detail"] {
                if let text = object[key] as? String, !text.isEmpty {
                    return text
                }
            }
            if let errors = object["errors"] as? [String: Any] {
                var parts: [String] = []
                for value in errors.values {
                    if let list = value as? [Any] {
                        let joined = list.compactMap { $0 as? String }.joined(separator: " ")
                        if !joined.isEmpty { parts.append(joined) }
                    } else if let text = value as? String, !text.isEmpty {
                        parts.append(text)
                    }
                }
                if !parts.isEmpty { return parts.joined(separator: "; ") }
            }
        }
        if let text = String(data: data, encoding: .utf8)?.trimmed, !text.isEmpty, text.count < 300 {
            return text
        }
        return nil
    }
}
