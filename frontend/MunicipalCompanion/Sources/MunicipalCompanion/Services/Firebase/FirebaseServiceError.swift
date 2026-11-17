import Foundation
import FirebaseAuth
import FirebaseFirestore

enum FirebaseServiceError: LocalizedError, Equatable {
    case notConfigured
    case unavailable
    case timedOut
    case permissionDenied
    case unauthenticated
    case notFound
    case duplicateSelection
    case cancelled
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Saving selections isn't set up yet."
        case .unavailable:
            return "Can't connect right now. Check your internet connection and try again."
        case .timedOut:
            return "This is taking longer than it should. Check your connection and try again."
        case .permissionDenied:
            return "You don't have access to that. You can only see and change your own selections."
        case .unauthenticated:
            return "Your session has expired. Sign out and back in to keep going."
        case .notFound:
            return "That selection isn't there anymore."
        case .duplicateSelection:
            return "You've already added this candidate."
        case .cancelled:
            return "The request was cancelled."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }

    init(underlying error: Error) {
        switch error {
        case let known as FirebaseServiceError:
            self = known
        case is CancellationError:
            self = .cancelled
        case let firestoreError as FirestoreErrorCode:
            self = Self.from(firestoreError.code) ?? .unknown(error.localizedDescription)
        case let urlError as URLError:
            self = urlError.code == URLError.timedOut ? .timedOut : .unavailable
        default:
            let nsError = error as NSError
            if nsError.domain == AuthErrors.domain, let code = AuthErrorCode(rawValue: nsError.code) {
                self = Self.from(code) ?? .unknown(error.localizedDescription)
            } else {
                self = .unknown(error.localizedDescription)
            }
        }
    }

    private static func from(_ code: FirestoreErrorCode.Code) -> FirebaseServiceError? {
        switch code {
        case FirestoreErrorCode.deadlineExceeded: return .timedOut
        case FirestoreErrorCode.notFound: return .notFound
        case FirestoreErrorCode.permissionDenied: return .permissionDenied
        case FirestoreErrorCode.unavailable: return .unavailable
        case FirestoreErrorCode.unauthenticated: return .unauthenticated
        case FirestoreErrorCode.cancelled: return .cancelled
        default: return nil
        }
    }

    private static func from(_ code: AuthErrorCode) -> FirebaseServiceError? {
        switch code {
        case AuthErrorCode.networkError:
            return .unavailable
        case AuthErrorCode.invalidCustomToken,
             AuthErrorCode.customTokenMismatch,
             AuthErrorCode.userTokenExpired,
             AuthErrorCode.userNotFound,
             AuthErrorCode.userDisabled:
            return .unauthenticated
        default:
            return nil
        }
    }
}
