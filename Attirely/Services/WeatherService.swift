import CoreLocation
import Foundation
import WeatherKit

enum WeatherError: LocalizedError {
    case fetchFailed(String)
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let detail): "Weather fetch failed: \(detail)"
        case .parsingFailed: "Could not parse weather data."
        }
    }
}

enum WeatherService {

    // MARK: - Unified Entry Point

    static func fetch(location: CLLocation) async -> Result<WeatherSnapshot, WeatherError> {
        // Try WeatherKit first
        if let snapshot = try? await fetchWeatherKit(location: location) {
            return .success(snapshot)
        }
        // Fall back to Open-Meteo
        do {
            let snapshot = try await fetchOpenMeteo(location: location)
            return .success(snapshot)
        } catch let error as WeatherError {
            return .failure(error)
        } catch {
            return .failure(.fetchFailed(error.localizedDescription))
        }
    }

    // MARK: - WeatherKit

    private static func fetchWeatherKit(location: CLLocation) async throws -> WeatherSnapshot {
        let service = WeatherKit.WeatherService.shared
        let weather = try await service.weather(for: location)

        let current = weather.currentWeather
        let hourly = Array(weather.hourlyForecast.prefix(12))

        let currentWeather = CurrentWeather(
            temperature: current.temperature.converted(to: .celsius).value,
            feelsLike: current.apparentTemperature.converted(to: .celsius).value,
            conditionDescription: current.condition.description,
            conditionSymbol: current.symbolName,
            humidity: current.humidity,
            windSpeed: current.wind.speed.converted(to: .kilometersPerHour).value,
            uvIndex: current.uvIndex.value,
            precipitationChance: hourly.first?.precipitationChance ?? 0
        )

        let forecasts = hourly.map { h in
            HourlyForecast(
                hour: h.date,
                temperature: h.temperature.converted(to: .celsius).value,
                conditionDescription: h.condition.description,
                conditionSymbol: h.symbolName,
                precipitationChance: h.precipitationChance
            )
        }

        return WeatherSnapshot(
            current: currentWeather,
            hourlyForecast: forecasts,
            fetchedAt: Date(),
            locationName: nil
        )
    }

    // MARK: - Open-Meteo Fallback

    private static func fetchOpenMeteo(location: CLLocation) async throws -> WeatherSnapshot {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let urlString = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(lat)&longitude=\(lon)"
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,precipitation_probability,weather_code,wind_speed_10m"
            + "&hourly=temperature_2m,precipitation_probability,weather_code"
            + "&timezone=auto&forecast_days=1"

        guard let url = URL(string: urlString) else {
            throw WeatherError.fetchFailed("Invalid URL")
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WeatherError.fetchFailed("HTTP error")
        }

        return try parseOpenMeteoResponse(data: data)
    }

    private static func parseOpenMeteoResponse(data: Data) throws -> WeatherSnapshot {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let current = json["current"] as? [String: Any]
        else {
            throw WeatherError.parsingFailed
        }

        let temp = current["temperature_2m"] as? Double ?? 0
        let feelsLike = current["apparent_temperature"] as? Double ?? temp
        let humidity = (current["relative_humidity_2m"] as? Double ?? 0) / 100.0
        let wind = current["wind_speed_10m"] as? Double ?? 0
        let precipChance = (current["precipitation_probability"] as? Double ?? 0) / 100.0
        let wmoCode = current["weather_code"] as? Int ?? 0

        let currentWeather = CurrentWeather(
            temperature: temp,
            feelsLike: feelsLike,
            conditionDescription: conditionDescription(for: wmoCode),
            conditionSymbol: symbolName(for: wmoCode),
            humidity: humidity,
            windSpeed: wind,
            uvIndex: 0,
            precipitationChance: precipChance
        )

        var forecasts: [HourlyForecast] = []
        if let hourly = json["hourly"] as? [String: Any] {
            let temps = hourly["temperature_2m"] as? [Double] ?? []
            let precips = hourly["precipitation_probability"] as? [Double] ?? []
            let codes = hourly["weather_code"] as? [Int] ?? []
            let times = hourly["time"] as? [String] ?? []

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
            formatter.timeZone = .current

            let now = Date()
            let limit = min(24, temps.count)
            for i in 0..<limit {
                let date = i < times.count ? (formatter.date(from: times[i]) ?? now) : now
                guard date >= now else { continue }
                if forecasts.count >= 12 { break }

                let code = i < codes.count ? codes[i] : 0
                forecasts.append(HourlyForecast(
                    hour: date,
                    temperature: temps[i],
                    conditionDescription: conditionDescription(for: code),
                    conditionSymbol: symbolName(for: code),
                    precipitationChance: (i < precips.count ? precips[i] : 0) / 100.0
                ))
            }
        }

        return WeatherSnapshot(
            current: currentWeather,
            hourlyForecast: forecasts,
            fetchedAt: Date(),
            locationName: nil
        )
    }

    // MARK: - WMO Weather Code Mapping

    static func symbolName(for wmoCode: Int) -> String {
        switch wmoCode {
        case 0: "sun.max.fill"
        case 1: "sun.min.fill"
        case 2: "cloud.sun.fill"
        case 3: "cloud.fill"
        case 45, 48: "cloud.fog.fill"
        case 51, 53, 55, 56, 57: "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67: "cloud.rain.fill"
        case 71, 73, 75, 77: "cloud.snow.fill"
        case 80, 81, 82: "cloud.heavyrain.fill"
        case 85, 86: "cloud.snow.fill"
        case 95, 96, 99: "cloud.bolt.rain.fill"
        default: "cloud.fill"
        }
    }

    static func conditionDescription(for wmoCode: Int) -> String {
        switch wmoCode {
        case 0: "Clear Sky"
        case 1: "Mainly Clear"
        case 2: "Partly Cloudy"
        case 3: "Overcast"
        case 45, 48: "Foggy"
        case 51, 53, 55: "Drizzle"
        case 56, 57: "Freezing Drizzle"
        case 61, 63, 65: "Rain"
        case 66, 67: "Freezing Rain"
        case 71, 73, 75: "Snow"
        case 77: "Snow Grains"
        case 80, 81, 82: "Rain Showers"
        case 85, 86: "Snow Showers"
        case 95: "Thunderstorm"
        case 96, 99: "Thunderstorm with Hail"
        default: "Cloudy"
        }
    }
}
