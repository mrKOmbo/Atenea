//
//  WatchConnectivityManager.swift
//  AteneaWatch Watch App
//
//  Created by Claude Code
//

import WatchConnectivity
import CoreLocation
import Combine

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    @Published var isNavigationActive: Bool = false
    @Published var currentLatitude: Double = 0.0
    @Published var currentLongitude: Double = 0.0
    @Published var destinationLatitude: Double = 0.0
    @Published var destinationLongitude: Double = 0.0
    @Published var destinationName: String = ""
    @Published var remainingDistance: Double = 0.0
    @Published var currentInstruction: String = ""
    @Published var recommendations: [WatchRecommendation] = []

    static let shared = WatchConnectivityManager()

    private override init() {
        super.init()
        setupWatchConnectivity()
    }

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    var currentLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: currentLatitude, longitude: currentLongitude)
    }

    var destinationLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: destinationLatitude, longitude: destinationLongitude)
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            handleReceivedMessage(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            handleReceivedMessage(applicationContext)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            handleReceivedMessage(userInfo)
        }
    }

    @MainActor
    private func handleReceivedMessage(_ message: [String: Any]) {
        print("📱 Watch received message: \(message)")

        // Verificar si es un mensaje de recomendaciones
        if let messageType = message["messageType"] as? String, messageType == "recommendations" {
            handleRecommendations(message)
            return
        }

        // Manejo de mensajes de navegación
        if let isActive = message["isNavigationActive"] as? Bool {
            self.isNavigationActive = isActive
            print("🧭 Navigation active: \(isActive)")
        }

        if let lat = message["currentLatitude"] as? Double {
            self.currentLatitude = lat
        }

        if let lon = message["currentLongitude"] as? Double {
            self.currentLongitude = lon
        }

        if let destLat = message["destinationLatitude"] as? Double {
            self.destinationLatitude = destLat
        }

        if let destLon = message["destinationLongitude"] as? Double {
            self.destinationLongitude = destLon
        }

        if let name = message["destinationName"] as? String {
            self.destinationName = name
            print("📍 Destination: \(name)")
        }

        if let distance = message["remainingDistance"] as? Double {
            self.remainingDistance = distance
            print("📏 Distance: \(distance)m")
        }

        if let instruction = message["currentInstruction"] as? String {
            self.currentInstruction = instruction
        }
    }

    @MainActor
    private func handleRecommendations(_ message: [String: Any]) {
        guard let recommendationsArray = message["recommendations"] as? [[String: Any]] else {
            print("⚠️ No se pudieron parsear las recomendaciones")
            return
        }

        let parsedRecommendations = recommendationsArray.compactMap { dict -> WatchRecommendation? in
            return WatchRecommendation(from: dict)
        }

        self.recommendations = parsedRecommendations
        print("✅ Recibidas \(parsedRecommendations.count) recomendaciones en el Watch")
    }
}
