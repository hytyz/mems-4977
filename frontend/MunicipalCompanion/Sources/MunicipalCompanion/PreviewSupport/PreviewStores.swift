#if DEBUG
import Foundation

final class PreviewFirebaseSession: FirebaseSessionProviding {
    func signIn(expectedUID: String?) async throws -> FirebaseIdentity {
        PreviewData.identity
    }

    func signOut() {}
}

final class PreviewUserProfileStore: UserProfileStore {
    private var profile: UserProfile?

    init(municipality: UserMunicipality? = PreviewData.userMunicipality) {
        profile = municipality.map {
            UserProfile(
                userEmail: PreviewData.identity.email,
                municipalityId: $0.id,
                municipalityName: $0.name,
                dateModified: PreviewData.electionDate
            )
        }
    }

    func loadProfile(for user: FirebaseIdentity) async throws -> UserProfile? {
        profile
    }

    func saveMunicipality(_ municipality: UserMunicipality, for user: FirebaseIdentity) async throws -> UserProfile {
        let saved = UserProfile(
            userEmail: user.email,
            municipalityId: municipality.id,
            municipalityName: municipality.name,
            dateModified: Date()
        )
        profile = saved
        return saved
    }
}

final class PreviewSelectionStore: SelectionStore {
    private var items: [CandidateSelection]

    init(items: [CandidateSelection] = PreviewData.selections) {
        self.items = items
    }

    func fetchSelections(for user: FirebaseIdentity, municipalityId: Int) async throws -> [CandidateSelection] {
        items.filter { $0.userEmail == user.email && $0.municipalityId == municipalityId }
    }

    func create(_ selection: CandidateSelection) async throws {
        if items.contains(where: { $0.id == selection.id }) {
            throw FirebaseServiceError.duplicateSelection
        }
        items.append(selection)
    }

    func updateNotes(_ notes: String, selectionId: String, modifiedAt: Date) async throws {
        guard let index = items.firstIndex(where: { $0.id == selectionId }) else {
            throw FirebaseServiceError.notFound
        }
        items[index].notes = notes
        items[index].dateModified = modifiedAt
    }

    func delete(selectionId: String) async throws {
        items.removeAll { $0.id == selectionId }
    }
}
#endif
