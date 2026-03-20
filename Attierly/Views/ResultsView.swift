import SwiftUI

struct ResultsView: View {
    let viewModel: ScanViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }

                if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Analyzing your clothes...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            viewModel.retry()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.scannedItems) { item in
                            ClothingItemCard(item: item)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom)
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }
}
