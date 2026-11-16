import SwiftUI

struct CandidateContactCard: View {
    let candidate: Candidate

    private var website: URL? {
        guard let value = candidate.website?.trimmed, !value.isEmpty,
              let url = URL(string: value), url.scheme != nil
        else { return nil }
        return url
    }

    private var email: String? {
        candidate.email?.trimmed.nonEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Contact")
                .font(.headline)
            if let website {
                Link(destination: website) {
                    Label(website.absoluteString, systemImage: "globe")
                        .lineLimit(1)
                }
            } else {
                Label("No website provided", systemImage: "globe")
                    .foregroundColor(.secondary)
            }
            if let email, let url = URL(string: "mailto:\(email)") {
                Link(destination: url) {
                    Label(email, systemImage: "envelope")
                        .lineLimit(1)
                }
            } else {
                Label("No email provided", systemImage: "envelope")
                    .foregroundColor(.secondary)
            }
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
