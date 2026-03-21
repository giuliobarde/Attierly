import Foundation

enum TemperatureFormatter {
    static func format(_ celsius: Double, unit: TemperatureUnit, includeUnit: Bool = true) -> String {
        switch unit {
        case .celsius:
            return includeUnit
                ? String(format: "%.0f°C", celsius)
                : String(format: "%.0f°", celsius)
        case .fahrenheit:
            let fahrenheit = celsius * 9.0 / 5.0 + 32.0
            return includeUnit
                ? String(format: "%.0f°F", fahrenheit)
                : String(format: "%.0f°", fahrenheit)
        }
    }
}
