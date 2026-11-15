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
