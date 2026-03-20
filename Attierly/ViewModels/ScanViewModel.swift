import SwiftUI

struct ScanSession: Identifiable {
    let id = UUID()
    let image: UIImage
    let items: [ClothingItem]
    let date: Date
}

@Observable
class ScanViewModel {
    var isLoading = false
    var scannedItems: [ClothingItem] = []
    var errorMessage: String?
    var selectedImage: UIImage?
    var showingCamera = false
    var showingResults = false
    var sessionHistory: [ScanSession] = []

    func analyzeImage(_ image: UIImage) {
        selectedImage = image
        showingResults = true
        isLoading = true
        errorMessage = nil
        scannedItems = []

        Task {
            do {
                let items = try await AnthropicService.analyzeClothing(image: image)
                if items.isEmpty {
                    self.errorMessage = "No clothing items detected. Try a clearer photo."
                } else {
                    self.scannedItems = items
                    self.sessionHistory.insert(
                        ScanSession(image: image, items: items, date: Date()),
                        at: 0
                    )
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    func retry() {
        guard let image = selectedImage else { return }
        analyzeImage(image)
    }
}
