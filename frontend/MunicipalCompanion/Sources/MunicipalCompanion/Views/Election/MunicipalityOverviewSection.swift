import SwiftUI

struct MunicipalityOverviewSection: View {
    let municipality: Municipality

    var body: some View {
        Section("Overview") {
            HStack(spacing: 12) {
                RemoteLogo(urlString: municipality.logoUrl, size: 56)
                VStack(alignment: .leading, spacing: 4) {
                    Text(municipality.name)
                        .font(.headline)
                    Text(municipality.province)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            LabeledContent(
                "Election Date",
                value: municipality.electionDate.formatted(date: .long, time: .omitted)
            )
            if let description = municipality.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
            }
        }
    }
}
