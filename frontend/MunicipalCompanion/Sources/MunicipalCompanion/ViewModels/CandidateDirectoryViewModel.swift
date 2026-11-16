import Foundation

#if canImport(Combine)
import Combine
#endif

@MainActor
final class CandidateDirectoryViewModel: ObservableObject {
    let municipality: UserMunicipality

    @Published var searchText = "" {
        didSet {
            if searchText.trimmed != lastSearchedText {
                scheduleSearch()
            }
        }
    }
    @Published var selectedPositionId: Int?
    @Published private(set) var candidates: [Candidate] = []
    @Published private(set) var positions: [Position] = []
    @Published private(set) var hasLoaded = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let api: ApiService
    private var searchTask: Task<Void, Never>?
    private var lastSearchedText = ""

    init(municipality: UserMunicipality, api: ApiService = .shared) {
        self.municipality = municipality
        self.api = api
    }

    var filteredCandidates: [Candidate] {
        guard let positionId = selectedPositionId else { return candidates }
        return candidates.filter { $0.positionId == positionId }
    }

    func positionName(_ id: Int) -> String? {
        positions.first { $0.id == id }?.name
    }

    var hasActiveFilters: Bool {
        selectedPositionId != nil
    }

    func loadIfNeeded() async {
        if !hasLoaded { await load() }
    }

    func load() async {
        searchTask?.cancel()
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let officeFetch = api.positions(city: municipality.name)
            let query = searchText.trimmed
            let fetched = try await api.candidates(city: municipality.name, name: query)
            let offices = try await officeFetch
            apply(candidates: fetched, for: query)
            positions = offices.filter { $0.municipalityId == municipality.id }
            if let selected = selectedPositionId, !positions.contains(where: { $0.id == selected }) {
                selectedPositionId = nil
            }
            hasLoaded = true
        } catch {
            if !isCancellation(error) {
                errorMessage = userMessage(for: error)
            }
        }
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            if Task.isCancelled { return }
            await self?.search()
        }
    }

    private func search() async {
        let query = searchText.trimmed
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fetched = try await api.candidates(city: municipality.name, name: query)
            guard !Task.isCancelled, query == searchText.trimmed else { return }
            apply(candidates: fetched, for: query)
        } catch {
            if !isCancellation(error) {
                errorMessage = userMessage(for: error)
            }
        }
    }

    private func apply(candidates fetched: [Candidate], for query: String) {
        candidates = fetched.filter { $0.municipalityId == municipality.id }
        lastSearchedText = query
    }
}
