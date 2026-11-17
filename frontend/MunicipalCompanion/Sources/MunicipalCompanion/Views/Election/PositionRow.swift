import SwiftUI

struct PositionRow: View {
    let position: Position
    var chosenCount = 0

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(position.name)
                    .font(.headline)
                Text(position.seatsAvailable == 1 ? "1 seat" : "\(position.seatsAvailable) seats")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 8)
            if chosenCount > 0 {
                Label("\(chosenCount) of \(position.seatsAvailable) selected", systemImage: "star.fill")
                    .font(.footnote)
                    .foregroundColor(.accentColor)
                    .labelStyle(.titleAndIcon)
            }
        }
    }
}

#if DEBUG
struct PositionRow_Previews: PreviewProvider {
    static var previews: some View {
        List(PreviewData.positions) { position in
            PositionRow(position: position, chosenCount: position.id == 1 ? 1 : 0)
        }
    }
}
#endif
