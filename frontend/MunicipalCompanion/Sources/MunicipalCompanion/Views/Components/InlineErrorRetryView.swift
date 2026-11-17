import SwiftUI

struct InlineErrorRetryView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ErrorMessageView(message: message)
            Button("Try Again", action: retry)
        }
    }
}

#if DEBUG
struct InlineErrorRetryView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Section("Positions") {
                InlineErrorRetryView(message: "Could not reach the server.") {}
            }
        }
    }
}
#endif
