import SwiftUI

struct SessionFailureView: View {
    let message: String
    let retry: () -> Void
    let logout: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("Couldn't Load Your Account")
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
            Button("Log Out", role: .destructive, action: logout)
        }
        .padding(24)
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
struct SessionFailureView_Previews: PreviewProvider {
    static var previews: some View {
        SessionFailureView(
            message: userMessage(for: FirebaseServiceError.unavailable),
            retry: {},
            logout: {}
        )
    }
}
#endif
