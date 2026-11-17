#if DEBUG
import SwiftUI

final class PreviewTokenStore: TokenStore {
    private var stored: StoredAuth?

    init(auth: StoredAuth?) {
        stored = auth
    }

    func save(_ auth: StoredAuth) { stored = auth }
    func load() -> StoredAuth? { stored }
    func clear() { stored = nil }
}

extension AuthManager {
    static var previewSignedIn: AuthManager {
        AuthManager(store: PreviewTokenStore(auth: PreviewData.auth))
    }

    static var previewSignedOut: AuthManager {
        AuthManager(store: PreviewTokenStore(auth: nil))
    }
}

@MainActor
final class PreviewContext: ObservableObject {
    let auth: AuthManager
    let session: SessionViewModel
    let selections: SelectionsViewModel
    let editor = SelectionEditorPresenter()

    init(signedIn: Bool = true, hasMunicipality: Bool = true) {
        auth = signedIn ? AuthManager.previewSignedIn : AuthManager.previewSignedOut
        session = SessionViewModel(
            auth: auth,
            firebase: PreviewFirebaseSession(),
            profiles: PreviewUserProfileStore(
                municipality: hasMunicipality ? PreviewData.userMunicipality : nil
            )
        )
        selections = SelectionsViewModel(store: PreviewSelectionStore(), api: .preview)
    }

    func start() async {
        await session.start()
        await selections.configure(user: session.user, municipality: session.municipality)
    }
}

private struct PreviewEnvironmentModifier: ViewModifier {
    @StateObject private var context = PreviewContext()

    func body(content: Content) -> some View {
        content
            .environmentObject(context.auth)
            .environmentObject(context.session)
            .environmentObject(context.selections)
            .environmentObject(context.editor)
            .task { await context.start() }
    }
}

extension View {
    func previewEnvironment() -> some View {
        modifier(PreviewEnvironmentModifier())
    }
}
#endif
