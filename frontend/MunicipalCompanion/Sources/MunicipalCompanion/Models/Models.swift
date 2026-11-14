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
    let biography: String?
    let photoUrl: String?
    let website: String?
    let email: String?
    let positionId: Int
    let municipalityId: Int
}

struct AuthResponse: Codable, Hashable {
    let token: String
    let email: String
    let fullName: String
}

struct FirebaseTokenResponse: Codable, Hashable {
    let token: String
    let uid: String
    let email: String
}
