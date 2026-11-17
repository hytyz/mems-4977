import SwiftUI

struct CandidateFilterMenu: View {
    let positions: [Position]
    @Binding var selectedPositionId: Int?

    var body: some View {
        Menu {
            Picker("Office", selection: $selectedPositionId) {
                Text("All Offices").tag(Int?.none)
                ForEach(positions) { position in
                    Text(position.name).tag(Int?.some(position.id))
                }
            }
        } label: {
            Label(
                "Filter",
                systemImage: selectedPositionId == nil
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill"
            )
        }
    }
}

#if DEBUG
struct CandidateFilterMenu_Previews: PreviewProvider {
    static var previews: some View {
        CandidateFilterMenu(positions: PreviewData.positions, selectedPositionId: .constant(nil))
            .padding()
    }
}
#endif
