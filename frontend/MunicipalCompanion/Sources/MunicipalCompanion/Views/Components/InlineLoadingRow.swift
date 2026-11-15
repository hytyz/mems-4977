import SwiftUI

struct InlineLoadingRow: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
}

#if DEBUG
struct InlineLoadingRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Section("Positions") {
                InlineLoadingRow()
            }
        }
    }
}
#endif
