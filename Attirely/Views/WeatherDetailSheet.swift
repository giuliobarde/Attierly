import SwiftUI

struct WeatherDetailSheet: View {
    @Bindable var viewModel: WeatherViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let snapshot = viewModel.snapshot {
                    ScrollView {
                        VStack(spacing: 16) {
                            currentConditionsCard(snapshot)
                            hourlyForecastSection(snapshot)
                            weatherOverrideToggle
                        }
                        .padding()
                    }
                } else {
                    permissionDeniedView
                }
            }
            .background(Theme.screenBackground)
            .navigationTitle("Weather")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Current Conditions

    private func currentConditionsCard(_ snapshot: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: snapshot.current.conditionSymbol)
                            .font(.largeTitle)
                            .foregroundStyle(Theme.champagne)
                        Text(String(format: "%.0f°C", snapshot.current.temperature))
                            .font(.largeTitle)
                            .fontWeight(.medium)
                            .foregroundStyle(Theme.primaryText)
                    }
                    Text(snapshot.current.conditionDescription)
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                    if let city = snapshot.locationName {
                        Text(city)
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                Spacer()
            }

            Divider()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                detailCell("Feels Like", String(format: "%.0f°C", snapshot.current.feelsLike))
                detailCell("Humidity", "\(Int(snapshot.current.humidity * 100))%")
                detailCell("Wind", String(format: "%.0f km/h", snapshot.current.windSpeed))
                detailCell("Precipitation", "\(Int(snapshot.current.precipitationChance * 100))%")
                if snapshot.current.uvIndex > 0 {
                    detailCell("UV Index", "\(snapshot.current.uvIndex)")
                }
            }
        }
        .themeCard()
    }

    // MARK: - Hourly Forecast

    private func hourlyForecastSection(_ snapshot: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Forecast")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Theme.secondaryText)
                .padding(.leading, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(snapshot.hourlyForecast) { hour in
                        hourlyCell(hour)
                    }
                }
            }
        }
    }

    private func hourlyCell(_ forecast: HourlyForecast) -> some View {
        VStack(spacing: 6) {
            Text(forecast.hour.formatted(.dateTime.hour()))
                .font(.caption2)
                .foregroundStyle(Theme.secondaryText)
            Image(systemName: forecast.conditionSymbol)
                .font(.subheadline)
                .foregroundStyle(Theme.champagne)
            Text(String(format: "%.0f°", forecast.temperature))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Theme.primaryText)
            if forecast.precipitationChance > 0.1 {
                Text("\(Int(forecast.precipitationChance * 100))%")
                    .font(.caption2)
                    .foregroundStyle(Theme.stone)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Theme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.cardBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Override Toggle

    private var weatherOverrideToggle: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Ignore weather for outfits", isOn: $viewModel.userOverridesWeather)
                .font(.subheadline)
                .foregroundStyle(Theme.primaryText)
                .tint(Theme.champagne)
            Text("When enabled, AI outfit generation will use only your selected occasion and season.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .themeCard()
    }

    // MARK: - Permission Denied

    private var permissionDeniedView: some View {
        ContentUnavailableView {
            Label("Location Access Needed", systemImage: "location.slash")
        } description: {
            Text("Enable location access in Settings to get weather-aware outfit suggestions.")
        } actions: {
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                Button("Open Settings") {
                    UIApplication.shared.open(settingsURL)
                }
                .buttonStyle(.themePrimary)
                .frame(width: 200)
            }
        }
    }

    // MARK: - Helpers

    private func detailCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Theme.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
