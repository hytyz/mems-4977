import SwiftUI

struct CityBadge: View {
    let city: String

    var body: some View {
        Label(city, systemImage: "mappin.and.ellipse")
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.accentColor.opacity(0.15)))
            .foregroundColor(.accentColor)
            .accessibilityLabel("City: \(city)")
    }
}

#if DEBUG
struct CityBadge_Previews: PreviewProvider {
    static var previews: some View {
        CityBadge(city: "Burnaby")
            .padding()
    }
}
#endif
