import SwiftUI

struct CandidateRow: View {
    let candidate: Candidate
    var positionName: String?
    var municipalityName: String?

    private var contestLine: String? {
        let parts = [positionName, municipalityName]
            .compactMap { $0?.trimmed }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            RemoteLogo(urlString: candidate.photoUrl, systemImage: "person.crop.circle.fill")
            VStack(alignment: .leading, spacing: 3) {
                Text(candidate.name)
                    .font(.headline)
                if let contestLine {
                    Text(contestLine)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                if let email = candidate.email?.trimmed, !email.isEmpty {
                    Text(email)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
