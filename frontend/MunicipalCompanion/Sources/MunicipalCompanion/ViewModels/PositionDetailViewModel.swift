import Foundation

#if canImport(Combine)
import Combine
#endif

@MainActor
final class PositionDetailViewModel: ObservableObject {
    let municipality: UserMunicipality

    @Published private(set) var candidates: [Candidate] = []
    @Published private(set) var hasLoaded = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let api: ApiService
    private let positionId: Int

    init(positionId: Int, municipality: UserMunicipality, api: ApiService = .shared) {
        self.positionId = positionId
        self.municipality = municipality
        self.api = api
    }

    func loadIfNeeded() async {
        if !hasLoaded { await load() }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let detail = try await api.position(id: positionId, city: municipality.name)
            candidates = (detail.candidates ?? [])
                .filter { $0.municipalityId == municipality.id }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            hasLoaded = true
        } catch {
            if !isCancellation(error) {
                errorMessage = userMessage(for: error)
            }
        }
    }
}
