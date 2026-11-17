import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionViewModel
    @EnvironmentObject private var selections: SelectionsViewModel
    @StateObject private var viewModel: ProfileViewModel
    @State private var isChangingMunicipality = false

    init() {
        _viewModel = StateObject(wrappedValue: ProfileViewModel())
    }

    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section("Account") {
                LabeledContent("Name", value: viewModel.fullName)
                LabeledContent("Email", value: viewModel.email)
            }

            Section {
                LabeledContent("City", value: session.municipality?.name ?? "Not set")
                Button {
                    isChangingMunicipality = true
                } label: {
                    Label("Change Municipality", systemImage: "mappin.and.ellipse")
                }
            } header: {
                Text("Municipality")
            } footer: {
                Text("Election data and selections are only shown for this municipality.")
            }

            Section {
                LabeledContent("Total Saved Selections", value: "\(selections.count)")
                LabeledContent("Last Synchronized", value: lastSyncText)
                Button {
                    Task { await selections.load() }
                } label: {
                    if selections.isLoading {
                        HStack {
                            ProgressView()
                            Text("Synchronizing…")
                        }
                    } else {
                        Label("Synchronize Now", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .disabled(selections.isLoading)
                if let message = selections.errorMessage {
                    ErrorMessageView(message: message)
                }
            } header: {
                Text("Candidate Selections")
            } footer: {
                if let city = session.municipality?.name {
                    Text("Selections are stored in Firebase. The total counts your selections in \(city).")
                }
            }

            ServerSettingsSection(viewModel: viewModel)

            Section {
                Button(role: .destructive) {
                    session.logout()
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $isChangingMunicipality) {
            NavigationStack {
                MunicipalityPickerView(purpose: .change)
            }
            .environmentObject(session)
        }
    }

    private var lastSyncText: String {
        guard let date = selections.lastSyncedAt else { return "Never" }
        return date.formatted(date: .abbreviated, time: .standard)
    }
}

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView(viewModel: ProfileViewModel(auth: AuthManager.previewSignedIn))
        }
        .previewEnvironment()
    }
}
#endif
