import Foundation

#if canImport(Combine)
import Combine
#endif

@MainActor
final class CandidateDetailViewModel: ObservableObject {
    let municipality: UserMunicipality

    @Published private(set) var candidate: Candidate?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let api: ApiService
    private let candidateId: Int
    private var hasRefreshed = false

    init(
        candidateId: Int,
        preloaded: Candidate? = nil,
        municipality: UserMunicipality,
        api: ApiService = .shared
    ) {
        self.candidateId = candidateId
        self.municipality = municipality
        self.api = api
        if let preloaded, preloaded.id == candidateId, preloaded.municipalityId == municipality.id {
            candidate = preloaded
        }
    }

    func loadIfNeeded() async {
        if !hasRefreshed { await load() }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fetched = try await api.candidate(id: candidateId, city: municipality.name)
            guard fetched.municipalityId == municipality.id else {
                throw ApiError.http(statusCode: 404, message: nil)
            }
            candidate = fetched
            hasRefreshed = true
        } catch {
            if isCancellation(error) { return }
            if let apiError = error as? ApiError, case .http(404, _) = apiError {
                candidate = nil
                errorMessage = "This candidate is not running in \(municipality.name)."
            } else if candidate == nil {
                errorMessage = userMessage(for: error)
            }
        }
    }
}
