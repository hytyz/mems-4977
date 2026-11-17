import Foundation

#if canImport(Combine)
import Combine
#endif

@MainActor
final class MunicipalityPickerViewModel: ObservableObject {
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
            if !isCancellation(error) {
                errorMessage = userMessage(for: error)
            }
        }
    }
}
