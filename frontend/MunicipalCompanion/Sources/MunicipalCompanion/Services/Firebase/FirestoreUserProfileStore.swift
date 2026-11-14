import Foundation
import FirebaseFirestore

final class FirestoreUserProfileStore: UserProfileStore {
    private func document(for user: FirebaseIdentity) -> DocumentReference {
        Firestore.firestore().collection(UserProfile.collectionName).document(user.uid)
    }

    func loadProfile(for user: FirebaseIdentity) async throws -> UserProfile? {
        let reference = document(for: user)
        return try await FirebaseCall.run {
            let snapshot = try await reference.getDocument()
            guard snapshot.exists else { return nil }
            return try snapshot.data(as: UserProfile.self)
        }
    }

    func saveMunicipality(_ municipality: UserMunicipality, for user: FirebaseIdentity) async throws -> UserProfile {
        let profile = UserProfile(
            userEmail: user.email,
            municipalityId: municipality.id,
            municipalityName: municipality.name,
            dateModified: Date()
        )
        let data = try Firestore.Encoder().encode(profile)

        let reference = document(for: user)
        try await FirebaseCall.run {
            try await reference.setData(data)
        }
        return profile
    }
}
