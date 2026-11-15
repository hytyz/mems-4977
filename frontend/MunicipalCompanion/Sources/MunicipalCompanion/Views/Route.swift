import Foundation

enum Route: Hashable {
    case position(Position)
    case candidate(Candidate)
    case candidateID(Int)
}
