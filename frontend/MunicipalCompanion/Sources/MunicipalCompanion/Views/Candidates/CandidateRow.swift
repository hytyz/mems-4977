import SwiftUI

struct CandidateRow: View {
    let candidate: Candidate
    var positionName: String?
    var isSelected = false

    var body: some View {
        HStack(spacing: 12) {
            RemoteLogo(urlString: candidate.photoUrl, systemImage: "person.crop.circle.fill")
            VStack(alignment: .leading, spacing: 3) {
                Text(candidate.name)
                    .font(.headline)
                if let positionName, !positionName.isEmpty {
                    Text(positionName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if isSelected {
                SelectedMark()
            }
        }
        .padding(.vertical, 2)
    }
}

struct SelectedMark: View {
    var body: some View {
        Image(systemName: "star.fill")
            .foregroundColor(.yellow)
            .accessibilityLabel("In your selections")
    }
}
