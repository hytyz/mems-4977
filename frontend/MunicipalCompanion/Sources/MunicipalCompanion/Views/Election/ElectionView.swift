import SwiftUI

struct ElectionView: View {
    @ObservedObject var viewModel: ElectionViewModel

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Municipal Elections Companion")
                        .font(.title3.weight(.semibold))
                    CityBadge(city: viewModel.municipality.name)
                }
                .padding(.vertical, 4)
            }

            if let election = viewModel.election {
                MunicipalityOverviewSection(municipality: election)
            }
            PositionsSection(viewModel: viewModel)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Election")
        .refreshable { await viewModel.load() }
        .task { await viewModel.loadIfNeeded() }
    }
}
