import SwiftUI

/// The user's voting guide: saved candidates with swipe-to-delete and an
/// explicit remove action via the context menu.
struct VotingGuideView: View {
    @EnvironmentObject private var viewModel: VotingGuideViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Voting Guide")
                .navigationDestination(for: Candidate.self) { candidate in
                    CandidateDetailView(candidate: candidate)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.saved.isEmpty {
            if let message = viewModel.errorMessage {
                ErrorRetryView(message: message) {
                    Task { await viewModel.load() }
                }
            } else if viewModel.isLoading {
                LoadingView(label: "Loading your guide…")
            } else {
                EmptyStateView(
                    title: "Your Guide Is Empty",
                    message: "Browse the Directory and add candidates you plan to vote for."
                )
            }
        } else {
            savedList
        }
    }

    private var savedList: some View {
        List {
            if let message = viewModel.errorMessage {
                Section {
                    ErrorMessageView(message: message)
                }
            }
            ForEach(viewModel.saved) { entry in
                NavigationLink(value: entry.candidate) {
                    HStack {
                        CandidateRow(candidate: entry.candidate)
                        Spacer()
                        Text(entry.dateSaved.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        Task { await viewModel.remove(savedCandidate: entry) }
                    } label: {
                        Label("Remove from Guide", systemImage: "trash")
                    }
                }
            }
            .onDelete { offsets in
                Task { await viewModel.remove(at: offsets) }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await viewModel.load() }
    }
}
