import SwiftUI
import SwiftData
import CoreLocation

@Observable
class ProfileViewModel {
    var isEditingName = false
    var editedName = ""
    var isGeocodingLocation = false
    var locationError: String?
    var locationCityInput = ""

    private var modelContext: ModelContext?

    // MARK: - Profile Singleton

    func ensureProfileExists(in context: ModelContext) {
        self.modelContext = context
        let descriptor = FetchDescriptor<UserProfile>()
        let existing = (try? context.fetch(descriptor)) ?? []
        if existing.isEmpty {
            let profile = UserProfile()
            context.insert(profile)
            try? context.save()
        }
    }

    // MARK: - Profile Photo

    func updateProfilePhoto(_ image: UIImage, profile: UserProfile) {
        if let oldPath = profile.profileImagePath {
            ImageStorageService.deleteImage(relativePath: oldPath)
        }
        if let path = try? ImageStorageService.saveProfileImage(image, id: profile.id) {
            profile.profileImagePath = path
            profile.updatedAt = Date()
            try? modelContext?.save()
        }
    }

    // MARK: - Name

    func saveName(_ name: String, profile: UserProfile) {
        profile.name = name.trimmingCharacters(in: .whitespaces)
        profile.updatedAt = Date()
        try? modelContext?.save()
        isEditingName = false
    }

    // MARK: - Preferences

    func updateTemperatureUnit(_ unit: TemperatureUnit, profile: UserProfile) {
        profile.temperatureUnit = unit
        profile.updatedAt = Date()
        try? modelContext?.save()
    }

    func updateThemePreference(_ theme: ThemePreference, profile: UserProfile) {
        profile.themePreference = theme
        profile.updatedAt = Date()
        try? modelContext?.save()
    }

    // MARK: - Location Override

    func toggleLocationOverride(_ enabled: Bool, profile: UserProfile) {
        profile.isLocationOverrideEnabled = enabled
        profile.updatedAt = Date()
        try? modelContext?.save()
    }

    func geocodeAndSaveLocation(profile: UserProfile) {
        let cityName = locationCityInput.trimmingCharacters(in: .whitespaces)
        guard !cityName.isEmpty else { return }
        isGeocodingLocation = true
        locationError = nil

        Task {
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.geocodeAddressString(cityName)
                if let location = placemarks.first?.location {
                    profile.locationOverrideName = cityName
                    profile.locationOverrideLat = location.coordinate.latitude
                    profile.locationOverrideLon = location.coordinate.longitude
                    profile.updatedAt = Date()
                    try? modelContext?.save()
                } else {
                    locationError = "Could not find that location."
                }
            } catch {
                locationError = "Location lookup failed. Check the city name."
            }
            isGeocodingLocation = false
        }
    }

    func clearLocationOverride(profile: UserProfile) {
        profile.locationOverrideName = nil
        profile.locationOverrideLat = nil
        profile.locationOverrideLon = nil
        profile.isLocationOverrideEnabled = false
        profile.updatedAt = Date()
        locationCityInput = ""
        try? modelContext?.save()
    }

    // MARK: - Analytics

    func categoryCounts(from items: [ClothingItem]) -> [(category: String, count: Int)] {
        var counts: [String: Int] = [:]
        for item in items { counts[item.category, default: 0] += 1 }
        return counts.map { (category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    func formalityCounts(from items: [ClothingItem]) -> [(formality: String, count: Int)] {
        let order = ["Casual", "Smart Casual", "Business Casual", "Business", "Formal"]
        var counts: [String: Int] = [:]
        for item in items { counts[item.formality, default: 0] += 1 }
        return counts.map { (formality: $0.key, count: $0.value) }
            .sorted { order.firstIndex(of: $0.formality) ?? 99 < order.firstIndex(of: $1.formality) ?? 99 }
    }

    func colorCounts(from items: [ClothingItem]) -> [(color: String, count: Int)] {
        var counts: [String: Int] = [:]
        for item in items { counts[item.primaryColor, default: 0] += 1 }
        return counts.map { (color: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
}
