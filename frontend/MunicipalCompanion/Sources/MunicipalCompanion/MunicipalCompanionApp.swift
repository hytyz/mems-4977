import SwiftUI

@main
struct MunicipalCompanionApp: App {
    @StateObject private var authManager: AuthManager
    @StateObject private var session: SessionViewModel
    @StateObject private var selections: SelectionsViewModel

    init() {
        FirebaseBootstrap.configure()

        let authManager = AuthManager.shared
        _authManager = StateObject(wrappedValue: authManager)
        _session = StateObject(
            wrappedValue: SessionViewModel(
                auth: authManager,
                firebase: FirebaseSessionService(),
                profiles: FirestoreUserProfileStore()
            )
        )
        _selections = StateObject(
            wrappedValue: SelectionsViewModel(store: FirestoreSelectionStore())
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(session)
                .environmentObject(selections)
        }
    }
}
