import Foundation
import FirebaseFirestore

final class FirestoreSelectionStore: SelectionStore {
    private var collection: CollectionReference {
        Firestore.firestore().collection(CandidateSelection.collectionName)
    }

    func fetchSelections(for user: FirebaseIdentity, municipalityId: Int) async throws -> [CandidateSelection] {
        let query = collection
            .whereField("userEmail", isEqualTo: user.email)
            .whereField("municipalityId", isEqualTo: municipalityId)

        return try await FirebaseCall.run {
            try await query.getDocuments().documents
                .compactMap { try? $0.data(as: CandidateSelection.self) }
                .filter { $0.userEmail == user.email && $0.municipalityId == municipalityId }
        }
    }

    func create(_ selection: CandidateSelection) async throws {
        let reference = collection.document(selection.id)
        let data = try Firestore.Encoder().encode(selection)

        let duplicateQuery = collection
            .whereField("userEmail", isEqualTo: selection.userEmail)
            .whereField("candidateId", isEqualTo: selection.candidateId)
            .limit(to: 1)

        try await FirebaseCall.run {
            let duplicates = try await duplicateQuery.getDocuments(source: .server)
            guard duplicates.isEmpty else { throw FirebaseServiceError.duplicateSelection }
            try await reference.setData(data)
        }
    }

    func updateNotes(_ notes: String, selectionId: String, modifiedAt: Date) async throws {
        let reference = collection.document(selectionId)
        try await FirebaseCall.run {
            try await reference.updateData([
                "notes": notes,
                "dateModified": Timestamp(date: modifiedAt)
            ])
        }
    }

    func delete(selectionId: String) async throws {
        let reference = collection.document(selectionId)
        try await FirebaseCall.run {
            try await reference.delete()
        }
    }
}
