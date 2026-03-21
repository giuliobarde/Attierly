import Foundation
import SwiftData

enum TemperatureUnit: String, Codable, CaseIterable {
    case celsius = "°C"
    case fahrenheit = "°F"
}

enum ThemePreference: String, Codable, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID

    // User details
    var name: String
    var profileImagePath: String?

    // Preferences (stored as raw strings for SwiftData compatibility)
    var temperatureUnitRaw: String
    var themePreferenceRaw: String

    // Location override
    var isLocationOverrideEnabled: Bool
    var locationOverrideName: String?
    var locationOverrideLat: Double?
    var locationOverrideLon: Double?

    var createdAt: Date
    var updatedAt: Date

    var temperatureUnit: TemperatureUnit {
        get { TemperatureUnit(rawValue: temperatureUnitRaw) ?? .celsius }
        set { temperatureUnitRaw = newValue.rawValue }
    }

    var themePreference: ThemePreference {
        get { ThemePreference(rawValue: themePreferenceRaw) ?? .system }
        set { themePreferenceRaw = newValue.rawValue }
    }

    init(name: String = "") {
        self.id = UUID()
        self.name = name
        self.temperatureUnitRaw = TemperatureUnit.celsius.rawValue
        self.themePreferenceRaw = ThemePreference.system.rawValue
        self.isLocationOverrideEnabled = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
