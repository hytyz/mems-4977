import Foundation

#if canImport(Combine)
import Combine
#endif

@MainActor
final class SessionViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case connecting
        case needsMunicipality
        case ready
        case failed(String)
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var user: FirebaseIdentity?
    @Published private(set) var municipality: UserMunicipality?
    @Published private(set) var isSavingMunicipality = false
    @Published var municipalityError: String?

    private let auth: AuthManager
    private let firebase: FirebaseSessionProviding
    private let profiles: UserProfileStore

    init(auth: AuthManager? = nil, firebase: FirebaseSessionProviding, profiles: UserProfileStore) {
        self.auth = auth ?? .shared
        self.firebase = firebase
        self.profiles = profiles
    }

    func start() async {
        guard auth.isAuthenticated else {
            endSession()
            return
        }
        phase = .connecting
        municipalityError = nil
        do {
            let identity = try await firebase.signIn(expectedUID: auth.userID)
            let profile = try await profiles.loadProfile(for: identity)
            guard auth.isAuthenticated else {
                endSession()
                return
            }
            user = identity
            municipality = profile?.municipality
            phase = profile == nil ? .needsMunicipality : .ready
        } catch {
            if isCancellation(error) { return }
            if let apiError = error as? ApiError, apiError.isUnauthorized {
                auth.expireSession()
                endSession()
                return
            }
            phase = .failed(userMessage(for: error))
        }
    }

    @discardableResult
    func chooseMunicipality(_ choice: Municipality) async -> Bool {
        guard let user else {
            municipalityError = userMessage(for: SelectionValidationError.notSignedIn)
            return false
        }
        if municipality?.id == choice.id { return true }
        guard !isSavingMunicipality else { return false }

        isSavingMunicipality = true
        municipalityError = nil
        defer { isSavingMunicipality = false }
        do {
            let profile = try await profiles.saveMunicipality(
                UserMunicipality(id: choice.id, name: choice.name),
                for: user
            )
            municipality = profile.municipality
            phase = .ready
            return true
        } catch {
            municipalityError = userMessage(for: error)
            return false
        }
    }

    func logout() {
        auth.signOut()
        endSession()
    }

    private func endSession() {
        firebase.signOut()
        user = nil
        municipality = nil
        municipalityError = nil
        phase = .idle
    }
}
