import Foundation

struct CurrentWeather {
    let temperature: Double
    let feelsLike: Double
    let conditionDescription: String
    let conditionSymbol: String
    let humidity: Double
    let windSpeed: Double
    let uvIndex: Int
    let precipitationChance: Double
}

struct HourlyForecast: Identifiable {
    let id = UUID()
    let hour: Date
    let temperature: Double
    let conditionDescription: String
    let conditionSymbol: String
    let precipitationChance: Double
}

struct WeatherSnapshot {
    let current: CurrentWeather
    let hourlyForecast: [HourlyForecast]
    let fetchedAt: Date
    let locationName: String?
}
