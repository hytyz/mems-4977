import SwiftUI

/// Red warning label used under forms and lists.
struct ErrorMessageView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundColor(.red)
    }
}

/// Centered empty-state message.
struct EmptyStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/// Centered loading indicator with an optional label.
struct LoadingView: View {
    var label: String = "Loading…"

    var body: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/// Error message plus a retry button, centered.
struct ErrorRetryView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/// AsyncImage-based logo/avatar with a graceful placeholder.
struct RemoteLogo: View {
    let urlString: String?
    var systemImage: String = "photo"
    var size: CGFloat = 48

    var body: some View {
        Group {
            if let url = mediaURL(from: urlString) {
                AsyncImage(url: url) { phase in
                    ZStack {
                        Color.gray.opacity(0.15)
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .empty:
                            ProgressView()
                        default:
                            Image(systemName: systemImage)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                ZStack {
                    Color.gray.opacity(0.15)
                    Image(systemName: systemImage)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Reusable list row for a candidate: photo, name, position and municipality.
struct CandidateRow: View {
    let candidate: Candidate
    /// Position name for the candidate, resolved by the view that owns the
    /// position/municipality lookup tables.
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

/// Reusable list row for a municipality (logo, name, province, election date).
struct MunicipalityRow: View {
    let municipality: Municipality

    var body: some View {
        HStack(spacing: 12) {
            RemoteLogo(urlString: municipality.logoUrl)
            VStack(alignment: .leading, spacing: 3) {
                Text(municipality.name)
                    .font(.headline)
                Text(municipality.province)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Election: \(municipality.electionDate.formatted(date: .long, time: .omitted))")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
