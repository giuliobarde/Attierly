import CoreLocation
import Foundation
import MapKit

enum LocationError: LocalizedError {
    case permissionDenied
    case permissionRestricted
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Location access was denied. Enable it in Settings to get weather-aware outfit suggestions."
        case .permissionRestricted:
            "Location access is restricted on this device."
        case .locationUnavailable:
            "Unable to determine your current location."
        }
    }
}

final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var authContinuation: CheckedContinuation<Void, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation, any Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestCurrentLocation() async throws -> CLLocation {
        let status = manager.authorizationStatus

        if status == .notDetermined {
            await withCheckedContinuation { continuation in
                authContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        }

        let currentStatus = manager.authorizationStatus
        guard currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways else {
            if currentStatus == .restricted {
                throw LocationError.permissionRestricted
            }
            throw LocationError.permissionDenied
        }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    static func reverseGeocode(location: CLLocation) async -> String? {
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        guard let mapItems = try? await request.mapItems,
              let mapItem = mapItems.first else { return nil }
        return mapItem.addressRepresentations?.cityWithContext
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if manager.authorizationStatus != .notDetermined {
                authContinuation?.resume()
                authContinuation = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            if let location = locations.first {
                locationContinuation?.resume(returning: location)
                locationContinuation = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        Task { @MainActor in
            locationContinuation?.resume(throwing: LocationError.locationUnavailable)
            locationContinuation = nil
        }
    }
}
