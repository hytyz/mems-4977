import Foundation

#if canImport(Combine)
import Combine
#endif

@MainActor
final class ElectionViewModel: ObservableObject {
    let municipality: UserMunicipality

    @Published private(set) var election: Municipality?
    @Published private(set) var positions: [Position] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let api: ApiService

    init(municipality: UserMunicipality, api: ApiService = .shared) {
        self.municipality = municipality
        self.api = api
    }

    func loadIfNeeded() async {
        if election == nil { await load() }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fetched = try await api.election(city: municipality.name)
            guard fetched.id == municipality.id else { throw ApiError.noElection(in: municipality.name) }
            election = fetched
            positions = (fetched.positions ?? []).filter { $0.municipalityId == municipality.id }
        } catch {
            if !isCancellation(error) {
                errorMessage = userMessage(for: error)
            }
        }
    }
}
