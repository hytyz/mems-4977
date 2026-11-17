import SwiftUI

struct RootView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var session: SessionViewModel
    @EnvironmentObject private var selections: SelectionsViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        content
            .task(id: authManager.auth?.token) {
                await session.start()
            }
            .task(id: SelectionContext(user: session.user, municipality: session.municipality)) {
                await selections.configure(user: session.user, municipality: session.municipality)
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    authManager.validateSession()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if !authManager.isAuthenticated {
            LoginView()
        } else {
            switch session.phase {
            case .idle, .connecting:
                LoadingView(label: "Connecting to your account…")
            case .failed(let message):
                SessionFailureView(
                    message: message,
                    retry: { Task { await session.start() } },
                    logout: { session.logout() }
                )
            case .needsMunicipality:
                NavigationStack {
                    MunicipalityPickerView(purpose: .firstLogin)
                }
            case .ready:
                if let municipality = session.municipality {
                    AppShellView(municipality: municipality)
                        .id(municipality.id)
                } else {
                    LoadingView(label: "Connecting to your account…")
                }
            }
        }
    }

    private struct SelectionContext: Equatable {
        let user: FirebaseIdentity?
        let municipality: UserMunicipality?
    }
}

#if DEBUG
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            root(PreviewContext(signedIn: false))
                .previewDisplayName("Signed out")
            root(PreviewContext(hasMunicipality: false))
                .previewDisplayName("First login")
            root(PreviewContext())
                .previewDisplayName("Signed in")
        }
    }

    @MainActor
    private static func root(_ context: PreviewContext) -> some View {
        RootView()
            .environmentObject(context.auth)
            .environmentObject(context.session)
            .environmentObject(context.selections)
            .task { await context.start() }
    }
}
#endif
