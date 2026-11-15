import SwiftUI

struct LoadingButton: View {
    let title: String
    var systemImage: String?
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            label
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var label: some View {
        if isLoading {
            ProgressView()
        } else if let systemImage {
            Label(title, systemImage: systemImage)
        } else {
            Text(title)
        }
    }
}

#if DEBUG
struct LoadingButton_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            LoadingButton(title: "Sign In", isLoading: false) {}
            LoadingButton(title: "Add to Voting Guide", systemImage: "star", isLoading: false) {}
            LoadingButton(title: "Sign In", isLoading: true) {}
        }
    }
}
#endif
