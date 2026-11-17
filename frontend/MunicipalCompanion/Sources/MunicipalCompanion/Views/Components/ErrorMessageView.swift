import SwiftUI

struct ErrorMessageView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundColor(.red)
    }
}

#if DEBUG
struct ErrorMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorMessageView(message: "Could not reach the server. Check your connection.")
            .padding()
    }
}
#endif
