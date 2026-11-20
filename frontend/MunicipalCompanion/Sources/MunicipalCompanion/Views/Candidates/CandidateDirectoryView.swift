import SwiftUI

struct CandidateDirectoryView: View {
    @ObservedObject var viewModel: CandidateDirectoryViewModel
    @EnvironmentObject private var selections: SelectionsViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        content
            .navigationTitle("Directory")
            .searchable(text: $viewModel.searchText, prompt: Text("Search by name"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CityBadge(city: viewModel.municipality.name)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    CandidateFilterMenu(
                        positions: viewModel.positions,
                        selectedPositionId: $viewModel.selectedPositionId
                    )
                }
            }
            .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.filteredCandidates.isEmpty {
            ListPlaceholderView(
                errorMessage: viewModel.errorMessage,
                isLoading: viewModel.isLoading || !viewModel.hasLoaded,
                loadingLabel: "Loading candidates…",
                emptyTitle: "No Candidates Found",
                emptyMessage: viewModel.hasActiveFilters
                    ? "No candidates in \(viewModel.municipality.name) match this office. Try another filter."
                    : "No candidates in \(viewModel.municipality.name) match your search.",
                retry: { Task { await viewModel.load() } }
            )
        } else {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        if let message = viewModel.errorMessage {
                            NoticeBanner(message: message) {
                                Task { await viewModel.load() }
                            }
                        }
                        Text(resultSummary)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        LazyVGrid(columns: columns(for: proxy.size.width), spacing: 12) {
                            ForEach(viewModel.filteredCandidates) { candidate in
                                NavigationLink(value: Route.candidate(candidate)) {
                                    CandidateCard(
                                        candidate: candidate,
                                        positionName: viewModel.positionName(candidate.positionId),
                                        isSelected: selections.isSelected(candidateId: candidate.id),
                                        style: style
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                }
                .refreshable { await viewModel.load() }
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private var resultSummary: String {
        let count = viewModel.filteredCandidates.count
        return "\(count) candidate\(count == 1 ? "" : "s") in \(viewModel.municipality.name)"
    }

    private var style: CandidateCard.Style {
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            return .tile
        }
        if verticalSizeClass == .compact {
            return .detailed
        }
        return .row
    }

    private func columns(for width: CGFloat) -> [GridItem] {
        let spacing: CGFloat = 12
        let minimumCardWidth: CGFloat
        switch style {
        case .row: minimumCardWidth = .greatestFiniteMagnitude
        case .detailed: minimumCardWidth = 340
        case .tile: minimumCardWidth = 220
        }
        let available = max(0, width - 32)
        let count = max(1, Int((available + spacing) / (minimumCardWidth + spacing)))
        return Array(repeating: GridItem(.flexible(), spacing: spacing, alignment: .top), count: count)
    }
}

#if DEBUG
struct CandidateDirectoryView_Previews: PreviewProvider {
    @MainActor static let viewModel = CandidateDirectoryViewModel(municipality: PreviewData.userMunicipality, api: .preview)

    static var previews: some View {
        NavigationStack {
            CandidateDirectoryView(viewModel: viewModel)
        }
        .previewEnvironment()
    }
}
#endif
