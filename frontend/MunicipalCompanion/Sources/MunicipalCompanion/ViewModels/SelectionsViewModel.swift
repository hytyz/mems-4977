import Foundation

#if canImport(Combine)
import Combine
#endif

@MainActor
final class SelectionsViewModel: ObservableObject {
    @Published private(set) var selections: [CandidateSelection] = []
    @Published private(set) var positions: [Int: Position] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var hasLoaded = false
    @Published private(set) var lastSyncedAt: Date?
    @Published var errorMessage: String?
    @Published var actionError: String?

    private let store: SelectionStore
    private let api: ApiService
    private var user: FirebaseIdentity?
    private var municipality: UserMunicipality?
    private var generation = 0

    init(store: SelectionStore, api: ApiService = .shared) {
        self.store = store
        self.api = api
    }

    func configure(user: FirebaseIdentity?, municipality: UserMunicipality?) async {
        guard user != self.user || municipality != self.municipality else { return }
        self.user = user
        self.municipality = municipality
        generation += 1
        selections = []
        positions = [:]
        hasLoaded = false
        isLoading = false
        lastSyncedAt = nil
        errorMessage = nil
        actionError = nil
        await load()
    }

    var count: Int { selections.count }

    var municipalityName: String? { municipality?.name }

    func selection(forCandidateId candidateId: Int) -> CandidateSelection? {
        selections.first { $0.candidateId == candidateId }
    }

    func isSelected(candidateId: Int) -> Bool {
        selection(forCandidateId: candidateId) != nil
    }

    func position(id: Int) -> Position? {
        positions[id]
    }

    func selections(forPositionId positionId: Int) -> [CandidateSelection] {
        selections.filter { $0.positionId == positionId }
    }

    func status(for candidate: Candidate) -> SelectionStatus {
        if let existing = selection(forCandidateId: candidate.id) {
            return .saved(existing)
        }
        let chosen = selections(forPositionId: candidate.positionId)
        guard let position = positions[candidate.positionId],
              chosen.count >= position.seatsAvailable
        else { return .available }
        return .seatsFilled(
            positionName: position.name,
            seats: position.seatsAvailable,
            chosen: chosen.map { $0.candidateName }
        )
    }

    func load() async {
        guard let user, let municipality else { return }
        let generation = self.generation
        isLoading = true
        errorMessage = nil
        defer {
            if generation == self.generation { isLoading = false }
        }
        do {
            async let officeFetch = api.positions(city: municipality.name)
            let fetched = try await store.fetchSelections(for: user, municipalityId: municipality.id)
            let offices = try? await officeFetch
            guard generation == self.generation else { return }

            selections = Self.sorted(fetched)
            if let offices {
                positions = Self.index(offices, municipalityId: municipality.id)
            }
            hasLoaded = true
            lastSyncedAt = Date()
        } catch {
            guard generation == self.generation, !isCancellation(error) else { return }
            errorMessage = userMessage(for: error)
        }
    }

    @discardableResult
    func add(candidate: Candidate, notes: String) async throws -> CandidateSelection {
        guard let user else { throw SelectionValidationError.notSignedIn }
        guard let municipality else { throw SelectionValidationError.noMunicipality }
        let notes = try Self.validatedNotes(notes)

        guard candidate.municipalityId == municipality.id else {
            throw SelectionValidationError.wrongMunicipality(
                candidateName: candidate.name,
                municipalityName: municipality.name
            )
        }
        let position = try await position(for: candidate, in: municipality)

        try Self.require(candidate.name, "candidate name")
        try Self.require(position.name, "office name")
        try Self.require(municipality.name, "municipality")
        try Self.require(user.email, "user email")

        switch status(for: candidate) {
        case .saved:
            throw SelectionValidationError.duplicate(candidateName: candidate.name)
        case .seatsFilled:
            throw SelectionValidationError.seatsFilled(
                message: status(for: candidate).blockedMessage ?? "No seats are left for this office."
            )
        case .available:
            break
        }

        let now = Date()
        let selection = CandidateSelection(
            id: CandidateSelection.documentID(uid: user.uid, candidateId: candidate.id),
            userEmail: user.email,
            candidateId: candidate.id,
            candidateName: candidate.name.trimmed,
            candidatePhotoUrl: candidate.photoUrl,
            positionId: position.id,
            positionName: position.name.trimmed,
            municipalityId: municipality.id,
            municipalityName: municipality.name,
            notes: notes,
            dateCreated: now,
            dateModified: now
        )

        let generation = self.generation
        do {
            try await store.create(selection)
        } catch FirebaseServiceError.duplicateSelection {
            await load()
            throw FirebaseServiceError.duplicateSelection
        }
        guard generation == self.generation else { return selection }
        selections = Self.sorted(selections.filter { $0.id != selection.id } + [selection])
        lastSyncedAt = now
        return selection
    }

    func update(_ selection: CandidateSelection, notes: String) async throws {
        guard user != nil else { throw SelectionValidationError.notSignedIn }
        let notes = try Self.validatedNotes(notes)
        guard selections.contains(where: { $0.id == selection.id }) else {
            throw SelectionValidationError.selectionMissing
        }

        let generation = self.generation
        let now = Date()
        try await store.updateNotes(notes, selectionId: selection.id, modifiedAt: now)
        guard generation == self.generation else { return }
        lastSyncedAt = now
    }

    func delete(_ selection: CandidateSelection) async {
        guard let index = selections.firstIndex(where: { $0.id == selection.id }) else { return }
        let generation = self.generation
        let removed = selections.remove(at: index)
        do {
            try await store.delete(selectionId: removed.id)
            if generation == self.generation { lastSyncedAt = Date() }
        } catch {
            guard generation == self.generation else { return }
            if !selections.contains(where: { $0.id == removed.id }) {
                selections = Self.sorted(selections + [removed])
            }
            actionError = "Couldn't remove \(removed.candidateName). \(userMessage(for: error))"
        }
    }

    static func validatedNotes(_ notes: String) throws -> String {
        let trimmed = notes.trimmed
        guard trimmed.count <= CandidateSelection.maxNotesLength else {
            throw SelectionValidationError.notesTooLong(count: trimmed.count)
        }
        return trimmed
    }

    private static func require(_ value: String, _ field: String) throws {
        if value.trimmed.isEmpty {
            throw SelectionValidationError.missingField(field)
        }
    }

    private func position(for candidate: Candidate, in municipality: UserMunicipality) async throws -> Position {
        if let known = positions[candidate.positionId] { return known }
        let fetched = try await api.position(id: candidate.positionId, city: municipality.name)
        guard fetched.municipalityId == municipality.id else {
            throw SelectionValidationError.wrongMunicipality(
                candidateName: candidate.name,
                municipalityName: municipality.name
            )
        }
        positions[fetched.id] = fetched
        return fetched
    }

    private static func index(_ offices: [Position], municipalityId: Int) -> [Int: Position] {
        let own = offices.filter { $0.municipalityId == municipalityId }
        return Dictionary(own.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private static func sorted(_ selections: [CandidateSelection]) -> [CandidateSelection] {
        selections.sorted {
            if $0.positionId != $1.positionId { return $0.positionId < $1.positionId }
            return $0.candidateName.localizedCaseInsensitiveCompare($1.candidateName) == .orderedAscending
        }
    }
}
