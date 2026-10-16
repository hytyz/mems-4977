import Foundation

struct Municipality: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let province: String
    let electionDate: Date
    let description: String?
    let logoUrl: String?
    var positions: [Position]?
}

struct Position: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let seatsAvailable: Int
    let municipalityId: Int
    var candidates: [Candidate]?
}

struct Candidate: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    /// Profile text; the API serializes null for candidates without one
    /// (CandidateDto.Biography is string?), so this must stay optional.
    let biography: String?
    let photoUrl: String?
    let website: String?
    let email: String?
    let positionId: Int
    let municipalityId: Int
}

struct SavedCandidate: Codable, Identifiable, Hashable {
    let id: Int
    let candidateId: Int
    let dateSaved: Date
    let candidate: Candidate
}

struct SavedCandidateCreated: Codable, Hashable {
    let id: Int
    let candidateId: Int
    let dateSaved: Date
}

struct AuthResponse: Codable, Hashable {
    let token: String
    let email: String
    let fullName: String
}
