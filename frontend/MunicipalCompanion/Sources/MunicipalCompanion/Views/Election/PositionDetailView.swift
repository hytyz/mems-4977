import SwiftUI

struct PositionDetailView: View {
    let position: Position
    @StateObject private var viewModel: PositionDetailViewModel
    @EnvironmentObject private var selections: SelectionsViewModel

    init(position: Position, municipality: UserMunicipality) {
        self.position = position
        _viewModel = StateObject(
            wrappedValue: PositionDetailViewModel(positionId: position.id, municipality: municipality)
        )
    }

    init(position: Position, viewModel: PositionDetailViewModel) {
        self.position = position
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section("Office") {
                LabeledContent("Name", value: position.name)
                LabeledContent("Municipality", value: viewModel.municipality.name)
                LabeledContent("Seats Available", value: "\(position.seatsAvailable)")
                LabeledContent(
                    "Your Selections",
                    value: "\(selections.selections(forPositionId: position.id).count) of \(position.seatsAvailable)"
                )
            }
            PositionCandidatesSection(positionName: position.name, viewModel: viewModel)
        }
        .listStyle(.insetGrouped)
        .navigationTitle(position.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.load() }
        .task { await viewModel.loadIfNeeded() }
    }
}

#if DEBUG
struct PositionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PositionDetailView(
                position: PreviewData.mayorPosition,
                viewModel: PositionDetailViewModel(
                    positionId: PreviewData.mayorPosition.id,
                    municipality: PreviewData.userMunicipality,
                    api: .preview
                )
            )
        }
        .previewEnvironment()
    }
}
#endif
