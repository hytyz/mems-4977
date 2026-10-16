import Foundation

#if canImport(Combine)
import Combine
#endif

@MainActor
final class MunicipalitiesViewModel: ObservableObject {
    @Published private(set) var municipalities: [Municipality] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let api: ApiService

    init(api: ApiService = .shared) {
        self.api = api
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            municipalities = try await api.municipalities()
        } catch {
            if !((error as? ApiError)?.isCancellation ?? false) {
                errorMessage = userMessage(for: error)
            }
        }
    }
}

/// Drives the Municipality detail screen (positions + candidates for that
/// municipality). The API returns the municipality with its positions; if
/// positions are absent, falls back to fetching all positions and filtering.
@MainActor
final class MunicipalityDetailViewModel: ObservableObject {
    @Published private(set) var municipality: Municipality?
    @Published private(set) var positions: [Position] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let api: ApiService
    private let municipalityId: Int

    init(municipalityId: Int, api: ApiService = .shared) {
        self.municipalityId = municipalityId
        self.api = api
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let detail = try await api.municipality(id: municipalityId)
            municipality = detail
            positions = detail.positions ?? []
            if positions.isEmpty {
                let all = try await api.positions()
                positions = all.filter { $0.municipalityId == municipalityId }
            }
        } catch {
            if !((error as? ApiError)?.isCancellation ?? false) {
                errorMessage = userMessage(for: error)
            }
        }
    }
}

/// Drives the Position detail screen (candidates running for that position).
@MainActor
final class PositionDetailViewModel: ObservableObject {
    @Published private(set) var position: Position?
    @Published private(set) var candidates: [Candidate] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let api: ApiService
    private let positionId: Int

    init(positionId: Int, api: ApiService = .shared) {
        self.positionId = positionId
        self.api = api
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let detail = try await api.position(id: positionId)
            position = detail
            candidates = detail.candidates ?? []
            if candidates.isEmpty {
                let all = try await api.candidates()
                candidates = all.filter { $0.positionId == positionId }
            }
        } catch {
            if !((error as? ApiError)?.isCancellation ?? false) {
                errorMessage = userMessage(for: error)
            }
        }
    }
}
