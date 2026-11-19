import SwiftUI

struct SelectedMark: View {
    var body: some View {
        Image(systemName: "star.fill")
            .foregroundColor(.yellow)
            .accessibilityLabel("In your selections")
    }
}

#if DEBUG
struct SelectedMark_Previews: PreviewProvider {
    static var previews: some View {
        SelectedMark()
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
