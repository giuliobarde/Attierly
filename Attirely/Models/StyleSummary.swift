import Foundation
import SwiftData

@Model
final class StyleSummary {
    @Attribute(.unique) var id: UUID

    var overallIdentity: String
    var styleModes: String?              // JSON-encoded [String]
    var temporalNotes: String?
    var gapObservations: String?
    var weatherBehavior: String?

    var lastAnalyzedAt: Date
    var itemCountAtLastAnalysis: Int
    var outfitCountAtLastAnalysis: Int
    var favoritedOutfitCountAtLastAnalysis: Int
    var analysisVersion: Int

    var isUserEdited: Bool
    var isAIEnriched: Bool

    var createdAt: Date

    var styleModesDecoded: [StyleModeDTO] {
        get {
            guard let data = styleModes?.data(using: .utf8),
                  let array = try? JSONDecoder().decode([StyleModeDTO].self, from: data)
            else { return [] }
            return array
        }
        set {
            styleModes = String(data: (try? JSONEncoder().encode(newValue)) ?? Data(), encoding: .utf8) ?? "[]"
        }
    }

    init(
        overallIdentity: String,
        itemCountAtLastAnalysis: Int = 0,
        outfitCountAtLastAnalysis: Int = 0,
        favoritedOutfitCountAtLastAnalysis: Int = 0
    ) {
        self.id = UUID()
        self.overallIdentity = overallIdentity
        self.lastAnalyzedAt = Date()
        self.itemCountAtLastAnalysis = itemCountAtLastAnalysis
        self.outfitCountAtLastAnalysis = outfitCountAtLastAnalysis
        self.favoritedOutfitCountAtLastAnalysis = favoritedOutfitCountAtLastAnalysis
        self.analysisVersion = 1
        self.isUserEdited = false
        self.isAIEnriched = false
        self.createdAt = Date()
    }
}
