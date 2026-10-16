import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let fullName: String
    let email: String
    let password: String
}

struct SaveCandidateRequest: Encodable {
    let candidateId: Int
}
