import SwiftUI

struct WeatherWidgetView: View {
    @Bindable var viewModel: WeatherViewModel

    var body: some View {
        switch viewModel.loadState {
        case .idle:
            EmptyView()

        case .requestingPermission, .loading:
            ProgressView()
                .scaleEffect(0.7)

        case .loaded(let snapshot):
            Button {
                viewModel.isShowingDetail = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: snapshot.current.conditionSymbol)
                        .font(.caption)
                        .foregroundStyle(Theme.champagne)
                    Text(String(format: "%.0f°", snapshot.current.temperature))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.primaryText)
                }
            }
            .sheet(isPresented: $viewModel.isShowingDetail) {
                WeatherDetailSheet(viewModel: viewModel)
            }

        case .permissionDenied:
            Button {
                viewModel.isShowingDetail = true
            } label: {
                Image(systemName: "location.slash")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            .sheet(isPresented: $viewModel.isShowingDetail) {
                WeatherDetailSheet(viewModel: viewModel)
            }

        case .failed:
            EmptyView()
        }
    }
}
