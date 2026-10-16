import Foundation

#if canImport(Combine)
import Combine
#endif

/// The signed-in user's voting guide: load, save, and remove candidates.
@MainActor
final class VotingGuideViewModel: ObservableObject {
    @Published private(set) var saved: [SavedCandidate] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    /// Feedback for the most recent save action ("Added X to your guide.").
    @Published var lastSaveFeedback: String?

    private let api: ApiService

    init(api: ApiService = .shared) {
        self.api = api
    }

    func savedIDs() -> Set<Int> {
        Set(saved.map { $0.candidateId })
    }

    func isSaved(candidateId: Int) -> Bool {
        savedIDs().contains(candidateId)
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            saved = try await api.savedCandidates()
        } catch {
            if !((error as? ApiError)?.isCancellation ?? false) {
                errorMessage = userMessage(for: error)
            }
        }
    }

    func save(candidate: Candidate) async {
        if isSaved(candidateId: candidate.id) { return }
        errorMessage = nil
        lastSaveFeedback = nil
        do {
            let created = try await api.saveCandidate(candidateId: candidate.id)
            saved.append(
                SavedCandidate(
                    id: created.id,
                    candidateId: created.candidateId,
                    dateSaved: created.dateSaved,
                    candidate: candidate
                )
            )
            lastSaveFeedback = "Added \(candidate.name) to your voting guide."
        } catch {
            if !((error as? ApiError)?.isCancellation ?? false) {
                errorMessage = userMessage(for: error)
            }
        }
    }

    func remove(at offsets: IndexSet) async {
        let validOffsets = offsets.filter { saved.indices.contains($0) }
        guard !validOffsets.isEmpty else { return }
        let targets = validOffsets.map { saved[$0] }
        saved = saved.enumerated()
            .filter { !validOffsets.contains($0.offset) }
            .map { $0.element }
        for target in targets {
            do {
                try await api.deleteSavedCandidate(id: target.id)
            } catch {
                if !((error as? ApiError)?.isCancellation ?? false) {
                    errorMessage = userMessage(for: error)
                }
                await load() // restore accurate state from the server
                return
            }
        }
    }

    func remove(savedCandidate: SavedCandidate) async {
        guard let index = saved.firstIndex(where: { $0.id == savedCandidate.id }) else { return }
        await remove(at: IndexSet(integer: index))
    }
}
