import SwiftUI

struct AppShellView: View {
    let municipality: UserMunicipality

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var selections: SelectionsViewModel
    @SceneStorage("appShell.selectedSection") private var storedSection = AppSection.election.rawValue
    @State private var paths: [AppSection: NavigationPath] = [:]
    @StateObject private var election: ElectionViewModel
    @StateObject private var directory: CandidateDirectoryViewModel
    @StateObject private var editor = SelectionEditorPresenter()

    init(municipality: UserMunicipality, api: ApiService = .shared) {
        self.municipality = municipality
        _election = StateObject(wrappedValue: ElectionViewModel(municipality: municipality, api: api))
        _directory = StateObject(wrappedValue: CandidateDirectoryViewModel(municipality: municipality, api: api))
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                splitLayout
            } else {
                tabLayout
            }
        }
        .environmentObject(editor)
        .sheet(item: $editor.editor) { viewModel in
            SelectionEditorView(viewModel: viewModel)
        }
        .alert("Selection Not Deleted", isPresented: deleteErrorIsPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(selections.actionError ?? "")
        }
    }

    private var tabLayout: some View {
        TabView(selection: sectionBinding) {
            ForEach(AppSection.allCases) { section in
                stack(for: section)
                    .tabItem {
                        Label(section.title, systemImage: section.systemImage)
                    }
                    .tag(section)
            }
        }
    }

    private var splitLayout: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: sidebarBinding) { section in
                Label(section.title, systemImage: section.systemImage)
            }
            .navigationTitle("Elections")
            .safeAreaInset(edge: .bottom) {
                CityBadge(city: municipality.name)
                    .padding()
            }
        } detail: {
            stack(for: section)
                .id(section)
        }
        .navigationSplitViewStyle(.balanced)
    }

    private func stack(for section: AppSection) -> some View {
        NavigationStack(path: pathBinding(for: section)) {
            root(for: section)
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
    }

    @ViewBuilder
    private func root(for section: AppSection) -> some View {
        switch section {
        case .election:
            ElectionView(viewModel: election)
        case .directory:
            CandidateDirectoryView(viewModel: directory)
        case .selections:
            SelectionsView()
        case .profile:
            ProfileView()
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .position(let position):
            PositionDetailView(position: position, municipality: municipality)
        case .candidate(let candidate):
            CandidateDetailView(candidate: candidate, municipality: municipality)
        case .candidateID(let candidateId):
            CandidateDetailView(candidateId: candidateId, municipality: municipality)
        }
    }

    private var section: AppSection {
        AppSection(rawValue: storedSection) ?? .election
    }

    private var sectionBinding: Binding<AppSection> {
        Binding(
            get: { section },
            set: { storedSection = $0.rawValue }
        )
    }

    private var sidebarBinding: Binding<AppSection?> {
        Binding(
            get: { section },
            set: { newValue in
                if let newValue { storedSection = newValue.rawValue }
            }
        )
    }

    private func pathBinding(for section: AppSection) -> Binding<NavigationPath> {
        Binding(
            get: { paths[section] ?? NavigationPath() },
            set: { paths[section] = $0 }
        )
    }

    private var deleteErrorIsPresented: Binding<Bool> {
        Binding(
            get: { selections.actionError != nil },
            set: { isPresented in
                if !isPresented { selections.actionError = nil }
            }
        )
    }
}

#if DEBUG
struct AppShellView_Previews: PreviewProvider {
    static var previews: some View {
        AppShellView(municipality: PreviewData.userMunicipality, api: .preview)
            .previewEnvironment()
    }
}
#endif
