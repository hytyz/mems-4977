import Foundation

#if canImport(Combine)
import Combine
#endif

@MainActor
final class SelectionEditorViewModel: ObservableObject, Identifiable {
    enum Mode: Identifiable, Hashable {
        case create(Candidate)
        case edit(CandidateSelection)

        var id: String {
            switch self {
            case .create(let candidate): return "create-\(candidate.id)"
            case .edit(let selection): return "edit-\(selection.id)"
            }
        }
    }

    let mode: Mode
    nonisolated var id: String { mode.id }
    @Published var notes: String
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    private let selections: SelectionsViewModel
    private let originalNotes: String

    init(mode: Mode, selections: SelectionsViewModel) {
        self.mode = mode
        self.selections = selections
        let existingNotes: String
        switch mode {
        case .create:
            existingNotes = ""
        case .edit(let selection):
            existingNotes = selection.notes
        }
        originalNotes = existingNotes
        notes = existingNotes
    }

    var title: String {
        switch mode {
        case .create: return "Add Selection"
        case .edit: return "Edit Selection"
        }
    }

    var saveTitle: String {
        switch mode {
        case .create: return "Add"
        case .edit: return "Save"
        }
    }

    var candidateName: String {
        switch mode {
        case .create(let candidate): return candidate.name
        case .edit(let selection): return selection.candidateName
        }
    }

    var photoUrl: String? {
        switch mode {
        case .create(let candidate): return candidate.photoUrl
        case .edit(let selection): return selection.candidatePhotoUrl
        }
    }

    var contestLine: String {
        switch mode {
        case .create(let candidate):
            let office = selections.position(id: candidate.positionId)?.name
            return [office, selections.municipalityName].compactMap { $0 }.joined(separator: " · ")
        case .edit(let selection):
            return "\(selection.positionName) · \(selection.municipalityName)"
        }
    }

    var characterCount: Int { notes.trimmed.count }

    var isOverLimit: Bool { characterCount > CandidateSelection.maxNotesLength }

    var counterText: String { "\(characterCount)/\(CandidateSelection.maxNotesLength)" }

    var hasUnsavedChanges: Bool { notes.trimmed != originalNotes.trimmed }

    var canSave: Bool {
        if isSaving || isOverLimit { return false }
        switch mode {
        case .create: return true
        case .edit: return hasUnsavedChanges
        }
    }

    func save() async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            switch mode {
            case .create(let candidate):
                try await selections.add(candidate: candidate, notes: notes)
            case .edit(let selection):
                try await selections.update(selection, notes: notes)
            }
            return true
        } catch {
            errorMessage = userMessage(for: error)
            return false
        }
    }
}

@MainActor
final class SelectionEditorPresenter: ObservableObject {
    @Published var editor: SelectionEditorViewModel?

    func present(_ mode: SelectionEditorViewModel.Mode, selections: SelectionsViewModel) {
        editor = SelectionEditorViewModel(mode: mode, selections: selections)
    }
}
