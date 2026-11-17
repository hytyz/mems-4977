import SwiftUI

struct ServerSettingsSection: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
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
            Text("The app uses the Azure deployment by default. Change this only to test against another copy of the Web API.")
        }
    }
}

#if DEBUG
struct ServerSettingsSection_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            ServerSettingsSection(viewModel: ProfileViewModel(auth: AuthManager.previewSignedIn))
        }
    }
}
#endif
