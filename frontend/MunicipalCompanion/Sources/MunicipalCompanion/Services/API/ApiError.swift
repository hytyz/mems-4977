import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum ApiError: LocalizedError {
    case invalidURL
    case invalidResponse
    case encoding(underlying: Error)
    case transport(underlying: Error)
    case http(statusCode: Int, message: String?)

    static func noElection(in city: String) -> ApiError {
        .http(statusCode: 404, message: "There's no election listed for \(city) yet.")
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The API Base URL doesn't look right, you can fix it on the Profile tab."
        case .invalidResponse:
            return "The server sent back something unexpected. Please try again."
        case .encoding:
            return "Something went wrong sending that. Please try again."
        case .transport(let underlying):
            return Self.transportMessage(for: underlying)
        case .http(let statusCode, let message):
            if let message = message?.trimmed, !message.isEmpty {
                return message
            }
            return Self.statusMessage(for: statusCode)
        }
    }

    var isUnauthorized: Bool {
        if case .http(let statusCode, _) = self { return statusCode == 401 }
        return false
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

    private static func statusMessage(for statusCode: Int) -> String {
        switch statusCode {
        case 400:
            return "That didn't go through. Check what you entered and try again."
        case 401:
            return "Your session has expired. Sign in again to keep going."
        case 403:
            return "You don't have permission to do that."
        case 404:
            return "We couldn't find that. It may have been removed."
        case 409:
            return "That already exists."
        case 500...599:
            return "The server ran into a problem."
        default:
            return "Something went wrong (error \(statusCode)). Please try again."
        }
    }

    private static func transportMessage(for error: Error) -> String {
        guard let code = (error as? URLError)?.code else {
            return "Couldn't connect to the server."
        }
        switch code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return "You're offline. Check your connection and try again."
        case .timedOut:
            return "The server is taking too long to respond."
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return "Can't reach the server."
        default:
            return "Couldn't connect to the server."
        }
    }

    static func serverMessage(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        if let object = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] {
            if let errors = object["errors"] as? [String: Any] {
                var parts: [String] = []
                for key in errors.keys.sorted() {
                    if let list = errors[key] as? [Any] {
                        let joined = list.compactMap { $0 as? String }.joined(separator: " ")
                        if !joined.isEmpty { parts.append(joined) }
                    } else if let text = errors[key] as? String, !text.isEmpty {
                        parts.append(text)
                    }
                }
                if !parts.isEmpty { return parts.joined(separator: " ") }
            }
            for key in ["detail", "message", "error", "title"] {
                if let text = object[key] as? String, !text.isEmpty {
                    return text
                }
            }
            return nil
        }
        if let text = String(data: data, encoding: .utf8)?.trimmed, !text.isEmpty, text.count < 300,
           !text.hasPrefix("<") {
            return text
        }
        return nil
    }
}
