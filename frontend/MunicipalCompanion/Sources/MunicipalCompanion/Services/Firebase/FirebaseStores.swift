import Foundation

protocol FirebaseSessionProviding {
    func signIn(expectedUID: String?) async throws -> FirebaseIdentity
    func signOut()
}

protocol UserProfileStore {
    func loadProfile(for user: FirebaseIdentity) async throws -> UserProfile?
    func saveMunicipality(_ municipality: UserMunicipality, for user: FirebaseIdentity) async throws -> UserProfile
}

protocol SelectionStore {
    func fetchSelections(for user: FirebaseIdentity, municipalityId: Int) async throws -> [CandidateSelection]
    func create(_ selection: CandidateSelection) async throws
    func updateNotes(_ notes: String, selectionId: String, modifiedAt: Date) async throws
    func delete(selectionId: String) async throws
}

enum FirebaseCall {
    static let defaultTimeout: TimeInterval = 15

    static func run<T>(
        timeout: TimeInterval = defaultTimeout,
        _ operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in
            let reply = ReplyOnce(continuation)

            let timer = Task {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                reply.send(.failure(FirebaseServiceError.timedOut))
            }

            Task {
                do {
                    reply.send(.success(try await operation()))
                } catch {
                    reply.send(.failure(FirebaseServiceError(underlying: error)))
                }
                timer.cancel()
            }
        }
    }

    private final class ReplyOnce<T> {
        private let lock = NSLock()
        private var continuation: CheckedContinuation<T, Error>?

        init(_ continuation: CheckedContinuation<T, Error>) {
            self.continuation = continuation
        }

        func send(_ result: Result<T, Error>) {
            lock.lock()
            let pending = continuation
            continuation = nil
            lock.unlock()
            pending?.resume(with: result)
        }
    }
}
