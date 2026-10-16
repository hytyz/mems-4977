import SwiftUI

struct MunicipalitiesView: View {
    @StateObject private var viewModel = MunicipalitiesViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Municipalities")
                .navigationDestination(for: Municipality.self) { municipality in
                    MunicipalityDetailView(municipality: municipality)
                }
                .task { await viewModel.load() }
                .refreshable { await viewModel.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.municipalities.isEmpty {
            if let message = viewModel.errorMessage {
                ErrorRetryView(message: message) {
                    Task { await viewModel.load() }
                }
            } else if viewModel.isLoading {
                LoadingView(label: "Loading municipalities…")
            } else {
                EmptyStateView(
                    title: "No Municipalities",
                    message: "The API did not return any municipalities yet."
                )
            }
        } else {
            List(viewModel.municipalities) { municipality in
                NavigationLink(value: municipality) {
                    MunicipalityRow(municipality: municipality)
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}
