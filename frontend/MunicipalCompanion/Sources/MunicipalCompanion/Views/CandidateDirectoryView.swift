import SwiftUI

/// Searchable, filterable directory of all candidates.
struct CandidateDirectoryView: View {
    @StateObject private var viewModel = CandidateDirectoryViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Directory")
                .searchable(text: $viewModel.searchText, prompt: Text("Search candidates by name"))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        filterMenu
                    }
                }
                .navigationDestination(for: Candidate.self) { candidate in
                    CandidateDetailView(candidate: candidate)
                }
                .task { await viewModel.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.filteredCandidates.isEmpty {
            if let message = viewModel.errorMessage {
                ErrorRetryView(message: message) {
                    Task { await viewModel.load() }
                }
            } else if viewModel.isLoading {
                LoadingView(label: "Loading candidates…")
            } else {
                EmptyStateView(
                    title: "No Candidates Found",
                    message: viewModel.hasActiveFilters
                        ? "No candidates match the current filters. Try clearing them."
                        : "Try a different search."
                )
            }
        } else {
            List {
                if let message = viewModel.errorMessage {
                    Section {
                        ErrorMessageView(message: message)
                    }
                }
                ForEach(viewModel.filteredCandidates) { candidate in
                    NavigationLink(value: candidate) {
                        CandidateRow(candidate: candidate)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable { await viewModel.load() }
        }
    }

    private var filterMenu: some View {
        Menu {
            Picker("Municipality", selection: $viewModel.selectedMunicipalityId) {
                Text("All Municipalities").tag(Int?.none)
                ForEach(viewModel.municipalities) { municipality in
                    Text(municipality.name).tag(Int?.some(municipality.id))
                }
            }
            Picker("Position", selection: $viewModel.selectedPositionId) {
                Text("All Positions").tag(Int?.none)
                ForEach(viewModel.positions) { position in
                    Text(position.name).tag(Int?.some(position.id))
                }
            }
            if viewModel.hasActiveFilters {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                }
            }
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
        }
    }
}
