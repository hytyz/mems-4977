import Foundation

struct UserMunicipality: Codable, Hashable, Identifiable {
    let id: Int
    let name: String
}

struct UserProfile: Codable, Hashable {
    var userEmail: String
    var municipalityId: Int
    var municipalityName: String
    var dateModified: Date

    static let collectionName = "UserProfiles"

    var municipality: UserMunicipality {
        UserMunicipality(id: municipalityId, name: municipalityName)
    }
}

struct FirebaseIdentity: Hashable {
    let uid: String
    let email: String
}
