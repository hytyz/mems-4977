import Foundation

enum SelectionStatus: Equatable {
    case available
    case saved(CandidateSelection)
    case seatsFilled(positionName: String, seats: Int, chosen: [String])

    var blockedMessage: String? {
        guard case let .seatsFilled(positionName, seats, chosen) = self else { return nil }
        let names = chosen.joined(separator: ", ")
        if seats <= 1 {
            return "You already chose \(names) for \(positionName). Only one candidate can be "
                + "selected for this office. Delete that selection to choose someone else."
        }
        return "You already chose \(seats) candidates for \(positionName) (\(names)), "
            + "which is the maximum. Delete one of those selections to add another."
    }
}

enum SelectionValidationError: LocalizedError, Equatable {
    case notSignedIn
    case noMunicipality
    case missingField(String)
    case notesTooLong(count: Int)
    case duplicate(candidateName: String)
    case seatsFilled(message: String)
    case wrongMunicipality(candidateName: String, municipalityName: String)
    case selectionMissing

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You need to be signed in to manage your selections."
        case .noMunicipality:
            return "Choose your municipality before selecting candidates."
        case .missingField(let field):
            return "The \(field) is missing, so this selection cannot be saved."
        case .notesTooLong(let count):
            return "Notes cannot exceed \(CandidateSelection.maxNotesLength) characters "
                + "(currently \(count))."
        case .duplicate(let candidateName):
            return "\(candidateName) is already in your selections."
        case .seatsFilled(let message):
            return message
        case .wrongMunicipality(let candidateName, let municipalityName):
            return "\(candidateName) is not a candidate in \(municipalityName)."
        case .selectionMissing:
            return "This selection no longer exists. Pull to refresh your selections."
        }
    }
}
