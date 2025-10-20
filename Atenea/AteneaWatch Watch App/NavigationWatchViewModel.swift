//
//  NavigationWatchViewModel.swift
//  AteneaWatch Watch App
//
//  Created by Claude Code
//

import SwiftUI
import CoreLocation
import Combine

@MainActor
class NavigationWatchViewModel: ObservableObject {
    @Published var arrowRotation: Double = 0.0
    @Published var distanceText: String = ""
    @Published var isNavigating: Bool = false

    private let compassManager = CompassManager()
    private let connectivityManager = WatchConnectivityManager.shared

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupObservers()
        compassManager.startUpdatingHeading()
    }

    private func setupObservers() {
        // Observar cambios en el heading del dispositivo
        Publishers.CombineLatest4(
            compassManager.$heading,
            connectivityManager.$currentLatitude,
            connectivityManager.$currentLongitude,
            Publishers.CombineLatest(
                connectivityManager.$destinationLatitude,
                connectivityManager.$destinationLongitude
            )
        )
        .sink { [weak self] heading, currentLat, currentLon, destinations in
            self?.updateArrowRotation(
                heading: heading,
                currentLat: currentLat,
                currentLon: currentLon,
                destLat: destinations.0,
                destLon: destinations.1
            )
        }
        .store(in: &cancellables)

        // Observar estado de navegación
        connectivityManager.$isNavigationActive
            .sink { [weak self] isActive in
                self?.isNavigating = isActive
            }
            .store(in: &cancellables)

        // Observar distancia restante
        connectivityManager.$remainingDistance
            .sink { [weak self] distance in
                self?.updateDistanceText(distance)
            }
            .store(in: &cancellables)
    }

    private func updateArrowRotation(heading: Double, currentLat: Double, currentLon: Double, destLat: Double, destLon: Double) {
        guard destLat != 0 && destLon != 0 else { return }

        let bearing = calculateBearing(
            from: CLLocationCoordinate2D(latitude: currentLat, longitude: currentLon),
            to: CLLocationCoordinate2D(latitude: destLat, longitude: destLon)
        )

        // La flecha apunta hacia el destino relativo al norte del dispositivo
        arrowRotation = bearing - heading
    }

    private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        let bearing = atan2(y, x) * 180 / .pi

        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }

    private func updateDistanceText(_ distance: Double) {
        if distance >= 1000 {
            distanceText = String(format: "%.1f km", distance / 1000)
        } else {
            distanceText = String(format: "%.0f m", distance)
        }
    }

    nonisolated deinit {
        // El CompassManager se limpiará automáticamente
    }
}
