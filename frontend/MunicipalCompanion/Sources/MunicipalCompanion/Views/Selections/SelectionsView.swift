import SwiftUI

struct SelectionsView: View {
    @EnvironmentObject private var selections: SelectionsViewModel
    @EnvironmentObject private var editor: SelectionEditorPresenter
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var pendingDelete: CandidateSelection?

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    summary
                    if selections.selections.isEmpty {
                        placeholder
                            .frame(minHeight: max(260, proxy.size.height - 160))
                    } else {
                        if let message = selections.errorMessage {
                            NoticeBanner(message: message) {
                                Task { await selections.load() }
                            }
                        }
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(selections.selections) { selection in
                                SelectionCard(
                                    selection: selection,
                                    onEdit: { editor.present(.edit(selection), selections: selections) },
                                    onDelete: { pendingDelete = selection }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .refreshable { await selections.load() }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("My Candidate Selections")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Delete Selection?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            presenting: pendingDelete
        ) { selection in
            Button("Delete", role: .destructive) {
                Task { await selections.delete(selection) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { selection in
            Text("\(selection.candidateName) and your notes will be removed from your selections.")
        }
    }

    private var columns: [GridItem] {
        if horizontalSizeClass == .compact && verticalSizeClass == .regular {
            return [GridItem(.flexible(), alignment: .top)]
        }
        return [GridItem(.adaptive(minimum: 320), spacing: 12, alignment: .top)]
    }

    private var summary: some View {
        HStack(alignment: .center, spacing: 12) {
            if let city = selections.municipalityName {
                CityBadge(city: city)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(selections.count) selected")
                    .font(.subheadline.weight(.semibold))
                Text(syncText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var syncText: String {
        guard let date = selections.lastSyncedAt else {
            return selections.isLoading ? "Syncing…" : "Not synced yet"
        }
        return "Synced \(date.formatted(date: .omitted, time: .shortened))"
    }

    @ViewBuilder
    private var placeholder: some View {
        if let message = selections.errorMessage {
            ErrorRetryView(message: message) {
                Task { await selections.load() }
            }
        } else if selections.isLoading || !selections.hasLoaded {
            LoadingView(label: "Loading your selections…")
        } else {
            EmptyStateView(
                title: "No Selections Yet",
                message: "Open a candidate from the Directory and tap Add Selection to save them here."
            )
        }
    }
}

#if DEBUG
struct SelectionsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SelectionsView()
        }
        .previewEnvironment()
    }
}
#endif
