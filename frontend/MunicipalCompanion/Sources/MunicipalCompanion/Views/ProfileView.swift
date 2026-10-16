import SwiftUI

/// Signed-in user overview, API base URL editing, and logout.
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    LabeledContent("Name", value: viewModel.fullName)
                    LabeledContent("Email", value: viewModel.email)
                }

                Section {
                    TextField("API Base URL", text: $viewModel.baseURLText)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Save API Base URL") {
                        viewModel.saveBaseURL()
                    }
                    Button("Reset to Default") {
                        viewModel.resetBaseURL()
                    }
                    if let message = viewModel.statusMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundColor(viewModel.isError ? .red : .secondary)
                    }
                } header: {
                    Text("Server")
                } footer: {
                    Text("The API runs on port 5000 of the host machine. Change this if the app cannot reach it.")
                }

                Section {
                    Button(role: .destructive) {
                        viewModel.logout()
                    } label: {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
