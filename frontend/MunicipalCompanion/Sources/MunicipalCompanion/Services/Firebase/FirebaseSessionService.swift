import Foundation
import FirebaseAuth

final class FirebaseSessionService: FirebaseSessionProviding {
    private let api: ApiService

    init(api: ApiService = .shared) {
        self.api = api
    }

    func signIn(expectedUID: String?) async throws -> FirebaseIdentity {
        guard FirebaseBootstrap.isConfigured else { throw FirebaseServiceError.notConfigured }
        let auth = Auth.auth()

        if let current = auth.currentUser, let expectedUID, current.uid == expectedUID,
           let email = await userEmailClaim(of: current) {
            return FirebaseIdentity(uid: current.uid, email: email)
        }

        try? auth.signOut()
        let response = try await api.firebaseToken()
        return try await FirebaseCall.run {
            let result = try await auth.signIn(withCustomToken: response.token)
            return FirebaseIdentity(uid: result.user.uid, email: response.email)
        }
    }

    func signOut() {
        guard FirebaseBootstrap.isConfigured else { return }
        try? Auth.auth().signOut()
    }

    private func userEmailClaim(of user: User) async -> String? {
        guard let result = try? await user.getIDTokenResult() else { return nil }
        return result.claims["userEmail"] as? String
    }
}
