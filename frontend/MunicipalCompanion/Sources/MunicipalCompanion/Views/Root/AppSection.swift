import Foundation

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case election
    case directory
    case selections
    case profile

    var id: AppSection { self }

    var title: String {
        switch self {
        case .election: return "Election"
        case .directory: return "Directory"
        case .selections: return "My Selections"
        case .profile: return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .election: return "building.columns.fill"
        case .directory: return "person.2.fill"
        case .selections: return "star.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

enum Route: Hashable {
    case position(Position)
    case candidate(Candidate)
    case candidateID(Int)
}
