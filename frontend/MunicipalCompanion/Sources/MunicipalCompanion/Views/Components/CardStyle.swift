import SwiftUI

struct CardStyle: ViewModifier {
    var padding: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = 14) -> some View {
        modifier(CardStyle(padding: padding))
    }
}

#if DEBUG
struct CardStyle_Previews: PreviewProvider {
    static var previews: some View {
        Text("Card content")
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
            .padding()
            .background(Color(.systemGroupedBackground))
    }
}
#endif
