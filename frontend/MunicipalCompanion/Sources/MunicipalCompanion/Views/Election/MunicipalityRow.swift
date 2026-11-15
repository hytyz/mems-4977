import SwiftUI

struct MunicipalityRow: View {
    let municipality: Municipality
    var isSelected = false

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
            Spacer(minLength: 8)
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
                    .accessibilityLabel("Current municipality")
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}
