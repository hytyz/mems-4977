import SwiftUI

struct RemoteLogo: View {
    let urlString: String?
    var systemImage: String = "photo"
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Color.gray.opacity(0.15)
            if let url = mediaURL(from: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        ProgressView()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: max(8, size * 0.08), style: .continuous))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.4))
            .foregroundColor(.secondary)
    }
}

#if DEBUG
struct RemoteLogo_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 16) {
            RemoteLogo(urlString: nil)
            RemoteLogo(urlString: nil, systemImage: "person.crop.circle.fill", size: 64)
        }
        .padding()
    }
}
#endif
