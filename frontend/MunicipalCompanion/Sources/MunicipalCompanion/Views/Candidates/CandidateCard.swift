import SwiftUI

struct CandidateCard: View {
    enum Style {
        case row
        case detailed
        case tile
    }

    let candidate: Candidate
    var positionName: String?
    var isSelected = false
    var style: Style = .row

    var body: some View {
        Group {
            switch style {
            case .row:
                CandidateRow(candidate: candidate, positionName: positionName, isSelected: isSelected)
            case .detailed:
                detailed
            case .tile:
                tile
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: style == .row ? 10 : 14)
        .contentShape(Rectangle())
    }

    private var detailed: some View {
        HStack(alignment: .top, spacing: 14) {
            RemoteLogo(urlString: candidate.photoUrl, systemImage: "person.crop.circle.fill", size: 72)
            VStack(alignment: .leading, spacing: 4) {
                header
                biography(lines: 2)
                contact
            }
        }
    }

    private var tile: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                RemoteLogo(urlString: candidate.photoUrl, systemImage: "person.crop.circle.fill", size: 96)
                Spacer(minLength: 8)
                if isSelected { SelectedMark() }
            }
            Text(candidate.name)
                .font(.headline)
                .lineLimit(2)
            if let positionName {
                Text(positionName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            biography(lines: 3)
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text(candidate.name)
                    .font(.headline)
                Spacer(minLength: 8)
                if isSelected { SelectedMark() }
            }
            if let positionName {
                Text(positionName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func biography(lines: Int) -> some View {
        if let biography = candidate.biography?.trimmed, !biography.isEmpty {
            Text(biography)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(lines)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var contact: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let email = candidate.email?.trimmed.nonEmpty {
                contactLine(email, systemImage: "envelope")
            }
            if let website = candidate.website?.trimmed.nonEmpty {
                contactLine(website, systemImage: "globe")
            }
        }
    }

    private func contactLine(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(1)
    }
}

extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
