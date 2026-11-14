import Foundation

#if canImport(Combine)
import Combine
#endif

@MainActor
final class SelectionsViewModel: ObservableObject {
    @Published private(set) var selections: [CandidateSelection] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasLoaded = false
    @Published var errorMessage: String?
    @Published var actionError: String?

    private let store: SelectionStore
    private var user: FirebaseIdentity?
    private var municipality: UserMunicipality?

    init(store: SelectionStore) {
        self.store = store
    }

    func configure(user: FirebaseIdentity?, municipality: UserMunicipality?) async {
        guard user != self.user || municipality != self.municipality else { return }
        self.user = user
        self.municipality = municipality
        selections = []
        hasLoaded = false
        errorMessage = nil
        actionError = nil
        await load()
    }

    var count: Int { selections.count }

    func selection(forCandidateId candidateId: Int) -> CandidateSelection? {
        selections.first { $0.candidateId == candidateId }
    }

    func isSelected(candidateId: Int) -> Bool {
        selection(forCandidateId: candidateId) != nil
    }

    func load() async {
        guard let user, let municipality else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fetched = try await store.fetchSelections(for: user, municipalityId: municipality.id)
            selections = fetched
            hasLoaded = true
        } catch {
            guard !isCancellation(error) else { return }
            errorMessage = userMessage(for: error)
        }
    }

    // TODO: seat limits, notes length, office lookup
    func add(candidate: Candidate, positionName: String, notes: String) async throws {
        guard let user else { throw SelectionValidationError.notSignedIn }
        guard let municipality else { throw SelectionValidationError.noMunicipality }
        if isSelected(candidateId: candidate.id) {
            throw SelectionValidationError.duplicate(candidateName: candidate.name)
        }

        let now = Date()
        let selection = CandidateSelection(
            id: CandidateSelection.documentID(uid: user.uid, candidateId: candidate.id),
            userEmail: user.email,
            candidateId: candidate.id,
            candidateName: candidate.name,
            candidatePhotoUrl: candidate.photoUrl,
            positionId: candidate.positionId,
            positionName: positionName,
            municipalityId: municipality.id,
            municipalityName: municipality.name,
            notes: notes.trimmed,
            dateCreated: now,
            dateModified: now
        )
        try await store.create(selection)
        selections.append(selection)
    }

    func delete(_ selection: CandidateSelection) async {
        do {
            try await store.delete(selectionId: selection.id)
            selections.removeAll { $0.id == selection.id }
        } catch {
            actionError = "\(selection.candidateName) could not be deleted. \(userMessage(for: error))"
        }
    }
}
