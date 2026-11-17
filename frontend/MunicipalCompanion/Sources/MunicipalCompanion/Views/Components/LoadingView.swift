import SwiftUI

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

#if DEBUG
struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView(label: "Loading candidates…")
    }
}
#endif
