import Foundation

#if canImport(Combine)
import Combine
#endif

/// Directory of candidates with text search (server-side) and optional
/// filtering by municipality and position (client-side).
@MainActor
final class CandidateDirectoryViewModel: ObservableObject {
    @Published var searchText = "" {
        didSet {
            if searchText.trimmed != lastSearchedText {
                reloadTask?.cancel()
                reloadTask = Task { await load() }
            }
        }
    }
    @Published var selectedMunicipalityId: Int?
    @Published var selectedPositionId: Int?
    @Published private(set) var candidates: [Candidate] = []
    @Published private(set) var municipalities: [Municipality] = []
    @Published private(set) var positions: [Position] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let api: ApiService
    private var reloadTask: Task<Void, Never>?
    private var lastSearchedText: String = ""

    init(api: ApiService = .shared) {
        self.api = api
    }

    var filteredCandidates: [Candidate] {
        candidates.filter { candidate in
            if let municipalityId = selectedMunicipalityId, candidate.municipalityId != municipalityId {
                return false
            }
            if let positionId = selectedPositionId, candidate.positionId != positionId {
                return false
            }
            return true
        }
    }

    func municipalityName(_ id: Int) -> String {
        municipalities.first { $0.id == id }?.name ?? "Municipality #\(id)"
    }

    func positionName(_ id: Int) -> String {
        positions.first { $0.id == id }?.name ?? "Position #\(id)"
    }

    var hasActiveFilters: Bool {
        selectedMunicipalityId != nil || selectedPositionId != nil
    }

    func clearFilters() {
        selectedMunicipalityId = nil
        selectedPositionId = nil
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let query = searchText.trimmed
            async let municipalityFetch = api.municipalities()
            async let positionFetch = api.positions()
            let fetched: [Candidate]
            if query.isEmpty {
                fetched = try await api.candidates()
            } else {
                fetched = try await api.searchCandidates(name: query)
            }
            let fetchedMunicipalities = try await municipalityFetch
            let fetchedPositions = try await positionFetch
            if Task.isCancelled { return }
            candidates = fetched
            municipalities = fetchedMunicipalities
            positions = fetchedPositions
            lastSearchedText = query
        } catch {
            if !((error as? ApiError)?.isCancellation ?? false) {
                errorMessage = userMessage(for: error)
            }
        }
    }
}

/// Loads a single candidate for the detail screen.
@MainActor
final class CandidateDetailViewModel: ObservableObject {
    @Published private(set) var candidate: Candidate?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let api: ApiService
    private let candidateId: Int

    init(candidateId: Int, api: ApiService = .shared) {
        self.candidateId = candidateId
        self.api = api
    }

    func load() async {
        if candidate != nil { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            candidate = try await api.candidate(id: candidateId)
        } catch {
            if !((error as? ApiError)?.isCancellation ?? false) {
                errorMessage = userMessage(for: error)
            }
        }
    }
}
