import SwiftUI

struct PositionCandidatesSection: View {
    let positionName: String
    @ObservedObject var viewModel: PositionDetailViewModel
    @EnvironmentObject private var selections: SelectionsViewModel

    var body: some View {
        Section("Candidates") {
            if viewModel.isLoading && viewModel.candidates.isEmpty {
                InlineLoadingRow()
            } else if let message = viewModel.errorMessage {
                InlineErrorRetryView(message: message) {
                    Task { await viewModel.load() }
                }
            } else if viewModel.candidates.isEmpty {
                Text("No candidates are running for this office.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.candidates) { candidate in
                    NavigationLink(value: Route.candidate(candidate)) {
                        CandidateRow(
                            candidate: candidate,
                            positionName: positionName,
                            isSelected: selections.isSelected(candidateId: candidate.id)
                        )
                    }
                }
            }
        }
    }
}

#if DEBUG
struct PositionCandidatesSection_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = PositionDetailViewModel(
            positionId: PreviewData.mayorPosition.id,
            municipality: PreviewData.userMunicipality,
            api: .preview
        )
        return NavigationStack {
            List {
                PositionCandidatesSection(
                    positionName: PreviewData.mayorPosition.name,
                    viewModel: viewModel
                )
            }
            .task { await viewModel.load() }
        }
        .previewEnvironment()
    }
}
#endif
