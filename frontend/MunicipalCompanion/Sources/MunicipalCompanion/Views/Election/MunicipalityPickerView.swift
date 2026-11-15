import SwiftUI

struct MunicipalityPickerView: View {
    enum Purpose {
        case firstLogin
        case change
    }

    let purpose: Purpose
    @EnvironmentObject private var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MunicipalityPickerViewModel

    init(purpose: Purpose) {
        self.purpose = purpose
        _viewModel = StateObject(wrappedValue: MunicipalityPickerViewModel())
    }

    init(purpose: Purpose, viewModel: MunicipalityPickerViewModel) {
        self.purpose = purpose
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle(purpose == .firstLogin ? "Your Municipality" : "Change Municipality")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    switch purpose {
                    case .firstLogin:
                        Button("Log Out") { session.logout() }
                    case .change:
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .disabled(session.isSavingMunicipality)
            .overlay {
                if session.isSavingMunicipality {
                    ProgressView("Saving…")
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.municipalities.isEmpty {
            ListPlaceholderView(
                errorMessage: viewModel.errorMessage,
                isLoading: viewModel.isLoading,
                loadingLabel: "Loading municipalities…",
                emptyTitle: "No Municipalities",
                emptyMessage: "The server did not return any municipalities yet.",
                retry: { Task { await viewModel.load() } }
            )
        } else {
            List {
                Section {
                    ForEach(viewModel.municipalities) { municipality in
                        Button {
                            choose(municipality)
                        } label: {
                            MunicipalityRow(
                                municipality: municipality,
                                isSelected: municipality.id == session.municipality?.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Where do you live?")
                } footer: {
                    Text(footerText)
                }

                if let message = session.municipalityError {
                    Section {
                        ErrorMessageView(message: message)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private var footerText: String {
        switch purpose {
        case .firstLogin:
            return "The app only shows the election, candidates and selections of your municipality. "
                + "You can change it later on the Profile screen."
        case .change:
            return "Changing your municipality reloads all election data. Selections you saved "
                + "for another municipality are kept, but only shown while you live there."
        }
    }

    private func choose(_ municipality: Municipality) {
        Task {
            let saved = await session.chooseMunicipality(municipality)
            if saved, purpose == .change {
                dismiss()
            }
        }
    }
}
