import SwiftUI

struct RemoteLogo: View {
    let urlString: String?
    var systemImage: String = "photo"
    var size: CGFloat = 48

    var body: some View {
        Group {
            if let url = mediaURL(from: urlString) {
                AsyncImage(url: url) { phase in
                    ZStack {
                        Color.gray.opacity(0.15)
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .empty:
                            ProgressView()
                        default:
                            Image(systemName: systemImage)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                ZStack {
                    Color.gray.opacity(0.15)
                    Image(systemName: systemImage)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
