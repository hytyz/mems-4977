import SwiftUI

struct CandidateDetailView: View {
    @StateObject private var viewModel: CandidateDetailViewModel
    @EnvironmentObject private var selections: SelectionsViewModel

    init(candidate: Candidate, municipality: UserMunicipality, api: ApiService = .shared) {
        _viewModel = StateObject(
            wrappedValue: CandidateDetailViewModel(
                candidateId: candidate.id,
                preloaded: candidate,
                municipality: municipality,
                api: api
            )
        )
    }

    init(candidateId: Int, municipality: UserMunicipality, api: ApiService = .shared) {
        _viewModel = StateObject(
            wrappedValue: CandidateDetailViewModel(candidateId: candidateId, municipality: municipality, api: api)
        )
    }

    var body: some View {
        content
            .navigationTitle(viewModel.candidate?.name ?? "Candidate")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        if let candidate = viewModel.candidate {
            GeometryReader { proxy in
                ScrollView {
                    layout(candidate, width: proxy.size.width)
                        .padding()
                        .frame(maxWidth: 1000)
                        .frame(maxWidth: .infinity)
                }
                .refreshable { await viewModel.load() }
            }
        } else {
            ListPlaceholderView(
                errorMessage: viewModel.errorMessage,
                isLoading: viewModel.isLoading || viewModel.errorMessage == nil,
                loadingLabel: "Loading candidate…",
                emptyTitle: "Candidate Not Found",
                emptyMessage: "This candidate could not be loaded.",
                retry: { Task { await viewModel.load() } }
            )
        }
    }

    @ViewBuilder
    private func layout(_ candidate: Candidate, width: CGFloat) -> some View {
        if width >= 600 {
            let photoSize = min(300, width * 0.32)
            HStack(alignment: .top, spacing: 20) {
                VStack(spacing: 12) {
                    RemoteLogo(urlString: candidate.photoUrl, systemImage: "person.crop.circle.fill", size: photoSize)
                    SelectionActionsCard(candidate: candidate)
                }
                .frame(width: photoSize)
                VStack(spacing: 12) {
                    infoCard(candidate)
                    CandidateContactCard(candidate: candidate)
                }
            }
        } else {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    RemoteLogo(urlString: candidate.photoUrl, systemImage: "person.crop.circle.fill", size: 110)
                    titleBlock(candidate)
                    Spacer(minLength: 0)
                }
                .cardStyle()
                biographyCard(candidate)
                SelectionActionsCard(candidate: candidate)
                CandidateContactCard(candidate: candidate)
            }
        }
    }

    private func infoCard(_ candidate: Candidate) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            titleBlock(candidate)
            Divider()
            biographyText(candidate)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func biographyCard(_ candidate: Candidate) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Biography")
                .font(.headline)
            biographyText(candidate)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func titleBlock(_ candidate: Candidate) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(candidate.name)
                .font(.title2.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            if let office = selections.position(id: candidate.positionId)?.name {
                Text(office)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            CityBadge(city: viewModel.municipality.name)
        }
    }

    @ViewBuilder
    private func biographyText(_ candidate: Candidate) -> some View {
        if let biography = candidate.biography?.trimmed, !biography.isEmpty {
            Text(biography)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text("This candidate has not provided a biography.")
                .foregroundColor(.secondary)
        }
    }
}

#if DEBUG
struct CandidateDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            detail(PreviewData.availableCandidate)
                .previewDisplayName("Can be added")
            detail(PreviewData.savedCandidate)
                .previewDisplayName("Already selected")
            detail(PreviewData.blockedCandidate)
                .previewDisplayName("Mayor already chosen")
        }
    }

    @MainActor
    private static func detail(_ candidate: Candidate) -> some View {
        NavigationStack {
            CandidateDetailView(candidate: candidate, municipality: PreviewData.userMunicipality, api: .preview)
        }
        .previewEnvironment()
    }
}
#endif
