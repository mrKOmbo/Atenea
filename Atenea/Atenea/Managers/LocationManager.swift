//
//  LocationManager.swift
//  Atenea
//
//  Created by Emilio Cruz Vargas on 10/10/25.
//

import Foundation
import CoreLocation
internal import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private lazy var navigationManager = NavigationManager.shared
    private var lastRecommendationUpdate: Date?

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var permissionDenied: Bool = false
    @Published var heading: CLHeading? // Dirección de la brújula

    override init() {
        // Inicializar el estado de autorización ANTES de llamar super.init()
        self.authorizationStatus = CLLocationManager().authorizationStatus
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Actualizar cada 10 metros

        // Configurar heading (brújula) - más sensible
        locationManager.headingFilter = 1 // Actualizar cada 1 grado para mayor precisión
        locationManager.headingOrientation = .portrait

        // Verificar y solicitar permisos automáticamente
        checkLocationAuthorization()
    }

    func startUpdatingHeading() {
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
            print("🧭 Iniciando actualizaciones de heading")
        }
    }

    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
        print("🧭 Deteniendo actualizaciones de heading")
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        print("📍 Iniciando actualizaciones continuas de ubicación")
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        print("📍 Deteniendo actualizaciones de ubicación")
    }

    private func checkLocationAuthorization() {
        switch authorizationStatus {
        case .notDetermined:
            print("🔑 Solicitando permisos de ubicación automáticamente...")
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Permisos ya autorizados, listo para usar ubicación")
            permissionDenied = false
        case .restricted, .denied:
            print("⚠️ Permiso de ubicación denegado o restringido")
            permissionDenied = true
        @unknown default:
            break
        }
    }

    func requestLocation() {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 Obteniendo ubicación actual...")
            locationManager.requestLocation()
        case .notDetermined:
            print("🔑 Solicitando permisos primero...")
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            permissionDenied = true
            print("❌ No se puede obtener ubicación. Permisos denegados.")
            print("💡 Ve a Configuración → Atenea → Ubicación → Permitir 'Mientras se usa'")
        @unknown default:
            break
        }
    }

    func checkAuthorization() -> Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    func requestPermission() {
        print("🔑 Solicitando permisos de ubicación...")
        locationManager.requestWhenInUseAuthorization()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        print("🔄 Estado de autorización cambió a: \(authorizationStatus.description)")

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            permissionDenied = false
            print("✅ Permisos de ubicación autorizados!")
        case .denied, .restricted:
            permissionDenied = true
            print("❌ Permisos de ubicación denegados")
        case .notDetermined:
            print("⏳ Permisos de ubicación aún no determinados")
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        print("✅ Ubicación obtenida: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        // Enviar recomendaciones al Watch si han pasado al menos 5 minutos
        let now = Date()
        let shouldUpdate = lastRecommendationUpdate == nil || now.timeIntervalSince(lastRecommendationUpdate!) > 300

        if shouldUpdate {
            sendRecommendationsToWatch(userLocation: location)
            lastRecommendationUpdate = now
        }
    }

    private func sendRecommendationsToWatch(userLocation: CLLocation) {
        // Enviar las recomendaciones usando el NavigationManager
        navigationManager.sendRecommendationsToWatch(venues: WorldCupVenue.allVenues, userLocation: userLocation)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as? CLError
        switch clError?.code {
        case .denied:
            permissionDenied = true
            print("❌ Error: Permisos de ubicación denegados")
        case .locationUnknown:
            print("⚠️ Ubicación desconocida temporalmente")
        default:
            print("⚠️ Error obteniendo ubicación: \(error.localizedDescription)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy >= 0 {
            self.heading = newHeading
            print("🧭 Heading actualizado: \(newHeading.trueHeading)° (precisión: \(newHeading.headingAccuracy)°)")
        } else {
            print("⚠️ Heading con baja precisión: \(newHeading.headingAccuracy)°")
        }
    }
}

// MARK: - Helper Extension
extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "No determinado"
        case .restricted: return "Restringido"
        case .denied: return "Denegado"
        case .authorizedAlways: return "Autorizado siempre"
        case .authorizedWhenInUse: return "Autorizado en uso"
        @unknown default: return "Desconocido"
        }
    }
}
