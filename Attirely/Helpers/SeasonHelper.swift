import Foundation

enum SeasonHelper {
    static func currentSeason(for date: Date = Date(), northernHemisphere: Bool = true) -> String {
        let month = Calendar.current.component(.month, from: date)
        let northernSeason: String
        switch month {
        case 3, 4, 5: northernSeason = "Spring"
        case 6, 7, 8: northernSeason = "Summer"
        case 9, 10, 11: northernSeason = "Fall"
        default: northernSeason = "Winter"
        }
        if northernHemisphere { return northernSeason }
        let flip = ["Spring": "Fall", "Fall": "Spring", "Summer": "Winter", "Winter": "Summer"]
        return flip[northernSeason] ?? northernSeason
    }

    static func weatherAdaptedSeason(calendarSeason: String, temperatureCelsius: Double) -> String {
        switch temperatureCelsius {
        case ..<5: return "Winter"
        case 5..<15: return "Fall"
        case 15..<24: return calendarSeason
        default: return "Summer"
        }
    }
}
