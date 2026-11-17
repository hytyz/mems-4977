import SwiftUI

struct ListPlaceholderView: View {
    let errorMessage: String?
    let isLoading: Bool
    let loadingLabel: String
    let emptyTitle: String
    let emptyMessage: String
    let retry: () -> Void

    var body: some View {
        if let errorMessage {
            ErrorRetryView(message: errorMessage, retry: retry)
        } else if isLoading {
            LoadingView(label: loadingLabel)
        } else {
            EmptyStateView(title: emptyTitle, message: emptyMessage)
        }
    }
}

#if DEBUG
struct ListPlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            placeholder(errorMessage: nil, isLoading: true)
                .previewDisplayName("Loading")
            placeholder(errorMessage: "Could not reach the server.", isLoading: false)
                .previewDisplayName("Error")
            placeholder(errorMessage: nil, isLoading: false)
                .previewDisplayName("Empty")
        }
    }

    @MainActor
    private static func placeholder(errorMessage: String?, isLoading: Bool) -> some View {
        ListPlaceholderView(
            errorMessage: errorMessage,
            isLoading: isLoading,
            loadingLabel: "Loading municipalities…",
            emptyTitle: "No Municipalities",
            emptyMessage: "The API did not return any municipalities yet.",
            retry: {}
        )
    }
}
#endif
