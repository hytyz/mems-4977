import SwiftUI

/// Municipality detail: overview plus the list of positions, which drill
/// down into the candidates running for each position.
struct MunicipalityDetailView: View {
    let municipality: Municipality
    @StateObject private var viewModel: MunicipalityDetailViewModel

    init(municipality: Municipality) {
        self.municipality = municipality
        _viewModel = StateObject(wrappedValue: MunicipalityDetailViewModel(municipalityId: municipality.id))
    }

    var body: some View {
        List {
            Section("Overview") {
                HStack(spacing: 12) {
                    RemoteLogo(urlString: municipality.logoUrl, size: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(municipality.name)
                            .font(.headline)
                        Text(municipality.province)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                LabeledContent(
                    "Election Date",
                    value: municipality.electionDate.formatted(date: .long, time: .omitted)
                )
                if let description = municipality.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                }
            }

            Section("Positions") {
                if viewModel.isLoading && viewModel.positions.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let message = viewModel.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        ErrorMessageView(message: message)
                        Button("Try Again") {
                            Task { await viewModel.load() }
                        }
                    }
                } else if viewModel.positions.isEmpty {
                    Text("No positions listed for this municipality.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.positions) { position in
                        NavigationLink(value: position) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(position.name)
                                    .font(.headline)
                                Text("Seats available: \(position.seatsAvailable)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(municipality.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Position.self) { position in
            PositionDetailView(position: position)
        }
        .task { await viewModel.load() }
    }
}

/// Position detail: seats available plus the candidates running.
struct PositionDetailView: View {
    let position: Position
    @StateObject private var viewModel: PositionDetailViewModel

    init(position: Position) {
        self.position = position
        _viewModel = StateObject(wrappedValue: PositionDetailViewModel(positionId: position.id))
    }

    var body: some View {
        List {
            Section("Position") {
                LabeledContent("Name", value: position.name)
                LabeledContent("Seats Available", value: "\(position.seatsAvailable)")
            }

            Section("Candidates") {
                if viewModel.isLoading && viewModel.candidates.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let message = viewModel.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        ErrorMessageView(message: message)
                        Button("Try Again") {
                            Task { await viewModel.load() }
                        }
                    }
                } else if viewModel.candidates.isEmpty {
                    Text("No candidates are running for this position.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.candidates) { candidate in
                        NavigationLink(value: candidate) {
                            CandidateRow(candidate: candidate)
                        }
                    }
                }
            }
        }
        .navigationTitle(position.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Candidate.self) { candidate in
            CandidateDetailView(candidate: candidate)
        }
        .task { await viewModel.load() }
    }
}
