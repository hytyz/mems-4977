import SwiftUI

struct PositionsSection: View {
    @ObservedObject var viewModel: ElectionViewModel
    @EnvironmentObject private var selections: SelectionsViewModel

    var body: some View {
        Section {
            if viewModel.isLoading && viewModel.positions.isEmpty {
                InlineLoadingRow()
            } else if let message = viewModel.errorMessage {
                InlineErrorRetryView(message: message) {
                    Task { await viewModel.load() }
                }
            } else if viewModel.positions.isEmpty {
                Text("No offices are listed for \(viewModel.municipality.name).")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.positions) { position in
                    NavigationLink(value: Route.position(position)) {
                        PositionRow(
                            position: position,
                            chosenCount: selections.selections(forPositionId: position.id).count
                        )
                    }
                }
            }
        } header: {
            Text("Offices")
        } footer: {
            Text("You can select as many candidates for an office as it has seats.")
        }
    }
}

#if DEBUG
struct PositionsSection_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ElectionViewModel(municipality: PreviewData.userMunicipality, api: .preview)
        return NavigationStack {
            List {
                PositionsSection(viewModel: viewModel)
            }
            .task { await viewModel.load() }
        }
        .previewEnvironment()
    }
}
#endif
