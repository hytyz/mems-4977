#if DEBUG
import Foundation

enum PreviewData {
    static let electionDate = Date(timeIntervalSince1970: 1_792_195_200)

    static let municipalities: [Municipality] = [
        Municipality(
            id: 1,
            name: "Pitt Meadows",
            province: "British Columbia",
            electionDate: electionDate,
            description: "A small city between the Fraser and Pitt rivers.",
            logoUrl: nil,
            positions: nil
        ),
        Municipality(
            id: 2,
            name: "Maple Ridge",
            province: "British Columbia",
            electionDate: electionDate,
            description: nil,
            logoUrl: nil,
            positions: nil
        )
    ]

    static let positions: [Position] = [
        Position(id: 1, name: "Mayor", seatsAvailable: 1, municipalityId: 1, candidates: nil),
        Position(id: 2, name: "Councillor", seatsAvailable: 6, municipalityId: 1, candidates: nil),
        Position(id: 3, name: "Mayor", seatsAvailable: 1, municipalityId: 2, candidates: nil)
    ]

    static let candidates: [Candidate] = [
        Candidate(
            id: 1,
            name: "Jordan Lee",
            biography: "Two-term councillor focused on transit and affordable housing.",
            photoUrl: nil,
            website: "https://example.com/jordan-lee",
            email: "jordan.lee@example.com",
            positionId: 1,
            municipalityId: 1
        ),
        Candidate(
            id: 2,
            name: "Morgan Chen",
            biography: "Small-business owner running on downtown revitalization.",
            photoUrl: nil,
            website: nil,
            email: "morgan.chen@example.com",
            positionId: 1,
            municipalityId: 1
        ),
        Candidate(
            id: 3,
            name: "Priya Nair",
            biography: nil,
            photoUrl: nil,
            website: nil,
            email: nil,
            positionId: 2,
            municipalityId: 1
        ),
        Candidate(
            id: 4,
            name: "Alex Tran",
            biography: "Urban planner with a passion for walkable neighbourhoods.",
            photoUrl: nil,
            website: "https://example.com/alex-tran",
            email: "alex.tran@example.com",
            positionId: 2,
            municipalityId: 1
        ),
        Candidate(
            id: 5,
            name: "Emily Carter",
            biography: "School trustee and parks advocate.",
            photoUrl: nil,
            website: "https://example.com/emily-carter",
            email: "emily.carter@example.com",
            positionId: 3,
            municipalityId: 2
        )
    ]

    static let auth = StoredAuth(
        token: "preview-token",
        email: "alex.voter@example.com",
        fullName: "Alex Voter"
    )

    static let identity = FirebaseIdentity(uid: "preview-user", email: auth.email)

    static let userMunicipality = UserMunicipality(id: 1, name: "Pitt Meadows")

    static let selections: [CandidateSelection] = [
        selection(for: candidates[0], notes: "Strong record on housing. Check the transit plan.", daysAgo: 10),
        selection(for: candidates[2], notes: "", daysAgo: 5)
    ]

    static func selection(for candidate: Candidate, notes: String, daysAgo: Double) -> CandidateSelection {
        let saved = electionDate.addingTimeInterval(-daysAgo * 86_400)
        return CandidateSelection(
            id: CandidateSelection.documentID(uid: identity.uid, candidateId: candidate.id),
            userEmail: identity.email,
            candidateId: candidate.id,
            candidateName: candidate.name,
            candidatePhotoUrl: candidate.photoUrl,
            positionId: candidate.positionId,
            positionName: positions.first { $0.id == candidate.positionId }?.name ?? "Office",
            municipalityId: candidate.municipalityId,
            municipalityName: municipalities.first { $0.id == candidate.municipalityId }?.name ?? "City",
            notes: notes,
            dateCreated: saved,
            dateModified: saved
        )
    }

    static var municipality: Municipality { municipalities[0] }
    static var mayorPosition: Position { positions[0] }
    static var savedCandidate: Candidate { candidates[0] }
    static var blockedCandidate: Candidate { candidates[1] }
    static var availableCandidate: Candidate { candidates[3] }
}
#endif
