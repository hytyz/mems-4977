import SwiftUI

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
