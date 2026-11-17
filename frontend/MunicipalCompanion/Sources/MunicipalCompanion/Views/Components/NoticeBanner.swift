import SwiftUI

struct NoticeBanner: View {
    let message: String
    var retry: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let retry {
                Button("Retry", action: retry)
                    .font(.footnote.weight(.semibold))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(0.12))
        )
    }
}

#if DEBUG
struct NoticeBanner_Previews: PreviewProvider {
    static var previews: some View {
        NoticeBanner(message: userMessage(for: FirebaseServiceError.unavailable), retry: {})
            .padding()
    }
}
#endif
