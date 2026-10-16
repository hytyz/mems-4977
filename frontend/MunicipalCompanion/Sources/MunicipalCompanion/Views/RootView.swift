import SwiftUI

/// Root of the app: shows the login screen when signed out, and the main
/// tab view (Guide | Municipalities | Directory | Profile) when signed in.
struct RootView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var votingGuideViewModel = VotingGuideViewModel()

    var body: some View {
        if authManager.isAuthenticated {
            mainTabs
                .environmentObject(votingGuideViewModel)
                .task(id: authManager.isAuthenticated) {
                    await votingGuideViewModel.load()
                }
        } else {
            LoginView()
        }
    }

    private var mainTabs: some View {
        TabView {
            VotingGuideView()
                .tabItem {
                    Label("Guide", systemImage: "star.fill")
                }
            MunicipalitiesView()
                .tabItem {
                    Label("Municipalities", systemImage: "building.columns.fill")
                }
            CandidateDirectoryView()
                .tabItem {
                    Label("Directory", systemImage: "person.3.fill")
                }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
    }
}
