//
//  NavigationManager.swift
//  Atenea
//
//  Gestor de navegación en tiempo real
//

import Foundation
import MapKit
import CoreLocation
internal import Combine
import ActivityKit
import WatchConnectivity

class NavigationManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = NavigationManager()

    // MARK: - Published Properties

    @Published var userLocation: CLLocationCoordinate2D?
    @Published var userHeading: CLLocationDirection = 0
    @Published var distanceRemaining: CLLocationDistance = 0
    @Published var timeRemaining: TimeInterval = 0
    @Published var currentStepIndex: Int = 0
    @Published var isNavigating: Bool = false
    @Published var hasArrived: Bool = false

    // MARK: - Private Properties

    private let locationManager = CLLocationManager()
    private var route: MKRoute?
    private var steps: [MKRoute.Step] = []
    private var destination: CLLocationCoordinate2D?
    private var destinationName: String = ""

    // Live Activity
    private var activity: Activity<NavigationActivityAttributes>?

    // MARK: - Initialization

    override init() {
        super.init()
        setupLocationManager()
        setupWatchConnectivity()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 10 // Actualizar cada 10 metros
        locationManager.requestWhenInUseAuthorization()
    }

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - Public Methods

    func startNavigation(route: MKRoute, destination: CLLocationCoordinate2D, destinationName: String = "Destino") {
        self.route = route
        self.destination = destination
        self.destinationName = destinationName
        self.steps = route.steps
        self.currentStepIndex = 0
        self.isNavigating = true
        self.hasArrived = false
        self.distanceRemaining = route.distance
        self.timeRemaining = route.expectedTravelTime

        // Iniciar seguimiento de ubicación
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()

        // Iniciar Live Activity
        startLiveActivity()

        // Enviar estado inicial al Watch
        sendNavigationDataToWatch()

        print("🧭 Navegación iniciada con \(steps.count) pasos")
    }

    func stopNavigation() {
        isNavigating = false
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()

        // Detener Live Activity
        stopLiveActivity()

        // Notificar al Watch que la navegación se detuvo
        sendNavigationDataToWatch()

        print("🛑 Navegación detenida")
    }

    var currentStep: MKRoute.Step? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }

    var nextStep: MKRoute.Step? {
        let nextIndex = currentStepIndex + 1
        guard nextIndex < steps.count else { return nil }
        return steps[nextIndex]
    }

    // MARK: - Private Methods

    private func updateNavigationState(for location: CLLocation) {
        guard let route = route, let destination = destination else { return }

        // Calcular distancia restante a lo largo de la ruta
        let currentCoordinate = location.coordinate
        let currentLocation = CLLocation(latitude: currentCoordinate.latitude, longitude: currentCoordinate.longitude)
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)

        distanceRemaining = currentLocation.distance(from: destinationLocation)

        // Calcular tiempo restante (estimación basada en velocidad promedio)
        let averageSpeed = route.expectedTravelTime > 0 ? route.distance / route.expectedTravelTime : 10.0 // m/s
        timeRemaining = distanceRemaining / averageSpeed

        // Verificar si llegamos al destino (dentro de 50 metros)
        if distanceRemaining < 50 {
            hasArrived = true
            stopNavigation()
            print("🎉 ¡Llegaste a tu destino!")
        }

        // Actualizar paso actual basado en distancia
        updateCurrentStep(for: currentCoordinate)

        // Actualizar Live Activity
        updateLiveActivity()

        // Enviar datos actualizados al Watch
        sendNavigationDataToWatch()
    }

    private func updateCurrentStep(for coordinate: CLLocationCoordinate2D) {
        guard currentStepIndex < steps.count else { return }

        let currentStep = steps[currentStepIndex]
        let stepLocation = CLLocation(
            latitude: currentStep.polyline.coordinate.latitude,
            longitude: currentStep.polyline.coordinate.longitude
        )
        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        // Si estamos muy cerca del final de este paso, avanzar al siguiente
        let distanceToStep = userLocation.distance(from: stepLocation)
        if distanceToStep < 30 && currentStepIndex < steps.count - 1 {
            currentStepIndex += 1
            print("➡️ Avanzando al paso \(currentStepIndex + 1) de \(steps.count)")
        }
    }

    // MARK: - Live Activity Management

    private func startLiveActivity() {
        // Verificar que Live Activities estén habilitadas
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live Activities no están habilitadas")
            return
        }

        // Intentar obtener una actividad existente primero
        let existingActivities = Activity<NavigationActivityAttributes>.activities
        if let existingActivity = existingActivities.first {
            // Usar la actividad existente y actualizarla
            activity = existingActivity
            print("✅ Usando Live Activity existente para navegación")
            updateLiveActivity()
            return
        }

        // Si no existe, crear una nueva
        let attributes = NavigationActivityAttributes(destinationName: destinationName)
        let initialState = NavigationActivityAttributes.ContentState(
            currentInstruction: currentStep?.instructions ?? "Continuar recto",
            distanceRemaining: distanceRemaining,
            timeRemaining: timeRemaining
        )

        do {
            // Iniciar la actividad
            activity = try Activity<NavigationActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            print("✅ Live Activity iniciada: \(destinationName)")
        } catch {
            print("❌ Error al iniciar Live Activity: \(error.localizedDescription)")
        }
    }

    private func updateLiveActivity() {
        guard let activity = activity else { return }

        // Crear estado actualizado
        let updatedState = NavigationActivityAttributes.ContentState(
            currentInstruction: currentStep?.instructions ?? "Continuar recto",
            distanceRemaining: distanceRemaining,
            timeRemaining: timeRemaining
        )

        // Actualizar de forma asíncrona
        Task {
            await activity.update(using: updatedState)
        }
    }

    private func stopLiveActivity() {
        guard let activity = activity else { return }

        // Finalizar la actividad
        Task {
            await activity.end(using: nil, dismissalPolicy: .immediate)
        }

        self.activity = nil
        print("✅ Live Activity detenida")
    }

    // MARK: - Watch Connectivity

    private func sendNavigationDataToWatch() {
        guard WCSession.default.isReachable else {
            // Si no está alcanzable, usar transferUserInfo para envío en background
            sendNavigationDataViaUserInfo()
            return
        }

        guard let destination = destination, let userLocation = userLocation else { return }

        let message: [String: Any] = [
            "isNavigationActive": isNavigating,
            "currentLatitude": userLocation.latitude,
            "currentLongitude": userLocation.longitude,
            "destinationLatitude": destination.latitude,
            "destinationLongitude": destination.longitude,
            "destinationName": destinationName,
            "remainingDistance": distanceRemaining,
            "currentInstruction": currentStep?.instructions ?? ""
        ]

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("⚠️ Error enviando mensaje al Watch: \(error.localizedDescription)")
        }
    }

    private func sendNavigationDataViaUserInfo() {
        guard let destination = destination, let userLocation = userLocation else { return }

        let userInfo: [String: Any] = [
            "isNavigationActive": isNavigating,
            "currentLatitude": userLocation.latitude,
            "currentLongitude": userLocation.longitude,
            "destinationLatitude": destination.latitude,
            "destinationLongitude": destination.longitude,
            "destinationName": destinationName,
            "remainingDistance": distanceRemaining,
            "currentInstruction": currentStep?.instructions ?? ""
        ]

        WCSession.default.transferUserInfo(userInfo)
    }

    // MARK: - Recommendations

    func sendRecommendationsToWatch(venues: [WorldCupVenue], userLocation: CLLocation) {
        guard WCSession.default.activationState == .activated else {
            print("⚠️ WCSession no está activado")
            return
        }

        // Ordenar venues por distancia y tomar los 5 más cercanos
        let sortedVenues = venues.sorted { venue1, venue2 in
            let location1 = CLLocation(latitude: venue1.coordinate.latitude, longitude: venue1.coordinate.longitude)
            let location2 = CLLocation(latitude: venue2.coordinate.latitude, longitude: venue2.coordinate.longitude)
            return userLocation.distance(from: location1) < userLocation.distance(from: location2)
        }.prefix(5)

        // Convertir a formato simplificado
        let recommendations: [[String: Any]] = sortedVenues.map { venue in
            return [
                "id": venue.id.uuidString,
                "name": venue.name,
                "city": venue.city,
                "country": venue.country,
                "latitude": venue.coordinate.latitude,
                "longitude": venue.coordinate.longitude,
                "hexColor": venue.hexColor,
                "nextMatch": venue.matches.first?.date ?? "Sin partidos programados",
                "funFact": venue.funFacts.randomElement() ?? ""
            ]
        }

        let message: [String: Any] = [
            "messageType": "recommendations",
            "recommendations": recommendations
        ]

        // Usar transferUserInfo para envío confiable en background
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("⚠️ Error enviando recomendaciones al Watch: \(error.localizedDescription)")
            }
        } else {
            WCSession.default.transferUserInfo(message)
        }

        print("✅ Enviadas \(recommendations.count) recomendaciones al Watch")
    }
}

// MARK: - CLLocationManagerDelegate

extension NavigationManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        userLocation = location.coordinate

        if isNavigating {
            updateNavigationState(for: location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        userHeading = newHeading.trueHeading
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Error de ubicación: \(error.localizedDescription)")
    }
}

// MARK: - WCSessionDelegate

extension NavigationManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("✅ WCSession activated: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("⚠️ WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("⚠️ WCSession deactivated")
        // Reactivar la sesión
        session.activate()
    }
}

// MARK: - Helper Extensions

extension MKRoute.Step {
    var instructionIcon: String {
        let instruction = instructions.lowercased()

        if instruction.contains("left") {
            return "arrow.turn.up.left"
        } else if instruction.contains("right") {
            return "arrow.turn.up.right"
        } else if instruction.contains("straight") || instruction.contains("continue") {
            return "arrow.up"
        } else if instruction.contains("arrive") || instruction.contains("destination") {
            return "mappin.circle.fill"
        } else {
            return "arrow.up"
        }
    }
}
