import SwiftUI

struct SelectionActionsCard: View {
    let candidate: Candidate
    @EnvironmentObject private var selections: SelectionsViewModel
    @EnvironmentObject private var editor: SelectionEditorPresenter
    @State private var pendingDelete: CandidateSelection?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Selection")
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
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

    @ViewBuilder
    private var content: some View {
        if !selections.hasLoaded {
            if let message = selections.errorMessage {
                InlineErrorRetryView(message: message) {
                    Task { await selections.load() }
                }
            } else {
                InlineLoadingRow()
            }
        } else {
            let status = selections.status(for: candidate)
            switch status {
            case .available:
                Button {
                    editor.present(.create(candidate), selections: selections)
                } label: {
                    Label("Add Selection", systemImage: "star")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            case .seatsFilled:
                Label(status.blockedMessage ?? "", systemImage: "hand.raised.fill")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            case .saved(let selection):
                savedContent(selection)
            }
        }
    }

    private func savedContent(_ selection: CandidateSelection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("In your selections", systemImage: "star.fill")
                .foregroundColor(.green)
            Text(selection.notes.isEmpty ? "No notes yet." : selection.notes)
                .font(.subheadline)
                .foregroundColor(selection.notes.isEmpty ? .secondary : .primary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Saved \(selection.dateCreated.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { editButton(selection); deleteButton(selection) }
                VStack(spacing: 8) { editButton(selection); deleteButton(selection) }
            }
        }
    }

    private func editButton(_ selection: CandidateSelection) -> some View {
        Button {
            editor.present(.edit(selection), selections: selections)
        } label: {
            Label("Edit Selection", systemImage: "pencil")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    private func deleteButton(_ selection: CandidateSelection) -> some View {
        Button(role: .destructive) {
            pendingDelete = selection
        } label: {
            Label("Delete Selection", systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}

#if DEBUG
struct SelectionActionsCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 12) {
                SelectionActionsCard(candidate: PreviewData.availableCandidate)
                SelectionActionsCard(candidate: PreviewData.savedCandidate)
                SelectionActionsCard(candidate: PreviewData.blockedCandidate)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewEnvironment()
    }
}
#endif
