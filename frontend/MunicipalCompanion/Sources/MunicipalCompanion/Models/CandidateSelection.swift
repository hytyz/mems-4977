import Foundation

struct CandidateSelection: Codable, Identifiable, Hashable {
    var id: String
    var userEmail: String
    var candidateId: Int
    var candidateName: String
    var candidatePhotoUrl: String?
    var positionId: Int
    var positionName: String
    var municipalityId: Int
    var municipalityName: String
    var notes: String
    var dateCreated: Date
    var dateModified: Date

    static let collectionName = "CandidateSelections"
    static let maxNotesLength = 500

    static func documentID(uid: String, candidateId: Int) -> String {
        "\(uid)_\(candidateId)"
    }

    var wasEdited: Bool {
        dateModified.timeIntervalSince(dateCreated) > 1
    }
}
