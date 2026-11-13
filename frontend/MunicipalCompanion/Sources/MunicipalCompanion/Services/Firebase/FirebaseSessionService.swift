import Foundation
import FirebaseAuth

final class FirebaseSessionService {
    private let api: ApiService

    init(api: ApiService = .shared) {
        self.api = api
    }

    func signIn() async throws -> String {
        guard FirebaseBootstrap.isConfigured else {
            throw ApiError.http(statusCode: 503, message: "Firebase is not configured.")
        }
        // TODO: reuse the current user if the uid still matches
        try? Auth.auth().signOut()
        let response = try await api.firebaseToken()
        let result = try await Auth.auth().signIn(withCustomToken: response.token)
        return result.user.uid
    }

    func signOut() {
        guard FirebaseBootstrap.isConfigured else { return }
        try? Auth.auth().signOut()
    }
}
