import SwiftUI

struct SelectionEditorView: View {
    @ObservedObject var viewModel: SelectionEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingDiscard = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        RemoteLogo(urlString: viewModel.photoUrl, systemImage: "person.crop.circle.fill")
                        VStack(alignment: .leading, spacing: 3) {
                            Text(viewModel.candidateName)
                                .font(.headline)
                            Text(viewModel.contestLine)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 140)
                        .accessibilityLabel("Notes")
                } header: {
                    Text("Notes")
                } footer: {
                    HStack(alignment: .top) {
                        Text("Optional. Why you chose this candidate, questions to follow up on, …")
                        Spacer(minLength: 12)
                        Text(viewModel.counterText)
                            .monospacedDigit()
                            .foregroundColor(viewModel.isOverLimit ? .red : .secondary)
                    }
                }

                if viewModel.isOverLimit {
                    Section {
                        ErrorMessageView(
                            message: "Notes cannot exceed \(CandidateSelection.maxNotesLength) characters."
                        )
                    }
                }

                if let message = viewModel.errorMessage {
                    Section {
                        ErrorMessageView(message: message)
                    }
                }
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if viewModel.hasUnsavedChanges {
                            isConfirmingDiscard = true
                        } else {
                            dismiss()
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button(viewModel.saveTitle) {
                            Task {
                                if await viewModel.save() {
                                    dismiss()
                                }
                            }
                        }
                        .disabled(!viewModel.canSave)
                    }
                }
            }
            .confirmationDialog(
                "Discard your changes?",
                isPresented: $isConfirmingDiscard,
                titleVisibility: .visible
            ) {
                Button("Discard Changes", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            }
        }
        .interactiveDismissDisabled(viewModel.hasUnsavedChanges || viewModel.isSaving)
    }
}

#if DEBUG
struct SelectionEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let selections = SelectionsViewModel(store: PreviewSelectionStore(), api: .preview)
        return Group {
            SelectionEditorView(
                viewModel: SelectionEditorViewModel(mode: .create(PreviewData.availableCandidate), selections: selections)
            )
            .previewDisplayName("Create")
            SelectionEditorView(
                viewModel: SelectionEditorViewModel(mode: .edit(PreviewData.selections[0]), selections: selections)
            )
            .previewDisplayName("Edit")
        }
    }
}
#endif
