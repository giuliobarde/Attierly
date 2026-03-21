import SwiftUI

struct MainTabView: View {
    @State private var weatherViewModel = WeatherViewModel()

    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(Theme.stone)
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.stone)
        ]
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Theme.obsidian),
            .font: UIFont.systemFont(ofSize: 34, weight: .medium)
        ]
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.obsidian),
            .font: UIFont.systemFont(ofSize: 17, weight: .medium)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }

    var body: some View {
        TabView {
            Tab("Scan", systemImage: "camera") {
                HomeView()
            }
            Tab("Outfits", systemImage: "sparkles") {
                OutfitsView(weatherViewModel: weatherViewModel)
            }
            Tab("Wardrobe", systemImage: "tshirt") {
                WardrobeView(weatherViewModel: weatherViewModel)
            }
        }
        .onAppear {
            weatherViewModel.fetchWeather()
        }
    }
}
