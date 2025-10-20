//
//  ARPosterViewModel.swift
//  Atenea
//
//  Created by Emilio Cruz Vargas on 07/10/25.
//

import SwiftUI
import UIKit
import ARKit
import RealityKit
internal import Combine

class ARPosterViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isTrackingReady: Bool = false
    @Published var detectedCity: String?
    @Published var showCityName: Bool = false
    @Published var showNavigationButton: Bool = false
    @Published var selectedVenue: WorldCupVenue?

    // Para detectar jugadores
    @Published var detectedPlayerName: String?
    @Published var showPlayerButton: Bool = false
    @Published var albumTargetPage: Int = 0

    // MARK: - Properties

    var arView: ARView?
    private var referenceImages: Set<ARReferenceImage> = []
    private var detectedAnchors: Set<UUID> = []

    // MARK: - City Data
    // IMPORTANTE: imageName debe coincidir EXACTAMENTE con el nombre de la carpeta .imageset en Assets

    private let cityData: [(name: String, imageName: String, isLogo: Bool)] = [
        // POSTERS COMPLETOS
        ("Atlanta", "Atlanta", false),                                    // ✅
        ("Boston", "Boston", false),                                      // ✅
        ("Dallas", "Dallas", false),                                      // ✅
        ("Guadalajara", "Guadalajara", false),                           // ✅
        ("Houston", "Houston", false),                                    // ✅
        ("Kansas City", "Kansas City", false),                            // ✅
        ("Los Angeles", "Los Angeles", false),                            // ✅
        ("Ciudad de México", "Mexico City", false),                       // ✅
        ("Miami", "Miami", false),                                        // ✅
        ("Monterrey", "Monterrey", false),                               // ✅
        ("Nueva York / Nueva Jersey", "New York, New Jersey", false),     // ✅ Nombre exacto del asset
        ("Philadelphia", "Philadelphia", false),                          // ✅
        ("San Francisco", "San Francisco BAV AREA", false),               // ✅ Nombre exacto del asset
        ("Seattle", "Seattle", false),                                    // ✅
        ("Toronto", "Toronto", false),                                    // ✅
        ("Vancouver", "Vancouver", false),                                // ✅

        // LOGOS DE SEDES (desde carpeta "Logo Cede")
        // Estos logos también detectan la misma ciudad que sus posters
        ("Guadalajara", "Guadalajara Logo", true),                        // ✅ Logo
        ("Kansas City", "Kansas City Logo", true),                        // ✅ Logo
        ("Los Angeles", "Los Angeles Logo", true),                        // ✅ Logo
        ("Ciudad de México", "Mexico City Logo", true),                   // ✅ Logo
        ("Monterrey", "Monterrey Logo", true),                            // ✅ Logo
        ("Philadelphia", "Philadelphia Logo", true),                      // ✅ Logo
        ("San Francisco", "San Francisco Logo", true),                    // ✅ Logo
        ("Toronto", "Toronto Logo", true),                                // ✅ Logo

        // JUGADORES - Prefijo "JUGADOR:" para distinguir de ciudades
        ("JUGADOR:Saad Al Sheeb", "s-l1200", false)                      // ✅ Jugador
    ]

    // MARK: - Initialization

    init() {
        loadReferenceImages()
    }

    deinit {
        print("🧹 ARPosterViewModel deinit - cleaning up")
        // Asegurarse de que la sesión se detenga
        if let arView = arView {
            arView.session.pause()
        }
        detectedAnchors.removeAll()
        referenceImages.removeAll()
    }

    // MARK: - Image Loading

    private func loadReferenceImages() {
        print("🔄 Starting to load reference images...")
        print("📋 Total items to load: \(cityData.count) (posters + logos)")

        for cityInfo in cityData {
            let (cityName, imageName, isLogo) = cityInfo

            // Intentar cargar la imagen desde Assets
            if let uiImage = UIImage(named: imageName) {
                print("🖼️ UIImage loaded for: \(imageName) \(isLogo ? "📌 LOGO" : "🖼️ POSTER")")

                if let cgImage = uiImage.cgImage {
                    // Tamaño físico según tipo:
                    // - Posters: 0.3 metros (30cm) - tamaño típico de poster
                    // - Logos: 0.15 metros (15cm) - más pequeños, mejor para detección cercana
                    // - Jugadores: 0.10 metros (10cm) - tarjetas de jugador
                    let isPlayer = cityName.hasPrefix("JUGADOR:")
                    let physicalWidth: CGFloat = isPlayer ? 0.10 : (isLogo ? 0.15 : 0.3)

                    let arImage = ARReferenceImage(cgImage, orientation: .up, physicalWidth: physicalWidth)
                    arImage.name = cityName
                    referenceImages.insert(arImage)

                    let imageType = isLogo ? "LOGO" : "POSTER"
                    print("✅ Loaded AR Reference [\(imageType)]: \(cityName) from '\(imageName)' (size: \(cgImage.width)x\(cgImage.height), physical: \(Int(physicalWidth * 100))cm)")
                } else {
                    print("❌ Failed to get CGImage from UIImage: \(imageName)")
                }
            } else {
                print("❌ Failed to load UIImage: '\(imageName)' for city: \(cityName)")
                if isLogo {
                    print("   💡 Logo asset name should be: '\(imageName)' in Assets.xcassets/Logo Cede/")
                } else {
                    print("   💡 Poster asset name should be: '\(imageName)' in Assets.xcassets/Poster PNG/")
                }
            }
        }

        print("📊 Total loaded: \(referenceImages.count) reference images out of \(cityData.count)")

        // Contar posters vs logos cargados
        let postersCount = cityData.filter { !$0.isLogo }.count
        let logosCount = cityData.filter { $0.isLogo }.count
        print("   🖼️ Posters: \(postersCount) | 📌 Logos: \(logosCount)")

        if referenceImages.count == 0 {
            print("⚠️ WARNING: No reference images were loaded! Check asset names.")
        } else if referenceImages.count < cityData.count {
            print("⚠️ Loaded \(referenceImages.count) out of \(cityData.count) total images")
        }
    }

    // MARK: - AR Session Setup

    func setupARSession(in arView: ARView) {
        self.arView = arView

        let configuration = ARImageTrackingConfiguration()

        if referenceImages.isEmpty {
            print("❌ No reference images loaded!")
        } else {
            configuration.trackingImages = referenceImages
            configuration.maximumNumberOfTrackedImages = 1
            print("🎯 AR Configuration set with \(referenceImages.count) images")
        }

        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        // Mark as ready after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isTrackingReady = true
        }
    }

    // MARK: - AR Frame Handling

    func handleARFrame(_ frame: ARFrame) {
        if frame.camera.trackingState == .normal && !isTrackingReady {
            DispatchQueue.main.async {
                self.isTrackingReady = true
            }
        }
    }

    // MARK: - Anchor Detection

    func handleAnchorAdded(_ anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }

        // Avoid duplicate detections
        guard !detectedAnchors.contains(anchor.identifier) else { return }
        detectedAnchors.insert(anchor.identifier)

        let detectedName = imageAnchor.referenceImage.name ?? "Desconocido"

        DispatchQueue.main.async {
            // Verificar si es un jugador
            if detectedName.hasPrefix("JUGADOR:") {
                self.handlePlayerDetection(detectedName, anchorId: anchor.identifier)
            } else {
                // Es una ciudad (lógica original)
                self.handleCityDetection(detectedName, anchorId: anchor.identifier)
            }
        }
    }

    // MARK: - Player Detection
    private func handlePlayerDetection(_ fullName: String, anchorId: UUID) {
        // Extraer nombre del jugador (quitar prefijo "JUGADOR:")
        let playerName = fullName.replacingOccurrences(of: "JUGADOR:", with: "")

        print("🎯 ¡JUGADOR DETECTADO!: \(playerName)")
        self.detectedPlayerName = playerName
        self.detectedCity = "Jugador: \(playerName)"

        // Determinar página del álbum según el jugador
        let albumPage = getAlbumPage(for: playerName)
        self.albumTargetPage = albumPage
        print("📖 Página del álbum configurada: \(albumPage + 1)")

        // FEEDBACK HÁPTICO - Vibración fuerte
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)

        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            self.showCityName = true
            self.showPlayerButton = true
        }

        // Ocultar nombre después de 4 segundos, pero mantener botón
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation {
                self.showCityName = false
            }
        }

        // Ocultar botón después de 10 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            withAnimation {
                self.showPlayerButton = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.detectedAnchors.remove(anchorId)
                self.detectedPlayerName = nil
            }
        }
    }

    // MARK: - Album Page Mapping
    private func getAlbumPage(for playerName: String) -> Int {
        // Mapeo de jugadores a páginas del álbum
        // Índice 0 = Página 1, Índice 9 = Página 10
        let playerPageMapping: [String: Int] = [
            "Saad Al Sheeb": 9  // Página 10
            // Agregar más jugadores aquí:
            // "Lionel Messi": 24,
        ]

        return playerPageMapping[playerName] ?? 0
    }

    // MARK: - City Detection
    private func handleCityDetection(_ cityName: String, anchorId: UUID) {
        print("🎉 Detected city: \(cityName)")
        self.detectedCity = cityName

        // FEEDBACK HÁPTICO - Vibración de éxito
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)

        // Feedback adicional con impacto medio
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Get venue data
        if let venue = self.getVenue(for: cityName) {
            self.selectedVenue = venue
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            self.showCityName = true
            self.showNavigationButton = true
        }

        // Hide city name after 4 seconds, but keep button
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation {
                self.showCityName = false
            }
        }

        // Hide button and clear detection after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            withAnimation {
                self.showNavigationButton = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.detectedAnchors.remove(anchorId)
                self.selectedVenue = nil
            }
        }
    }

    func handleAnchorUpdated(_ anchor: ARAnchor) {
        // Keep tracking active
    }

    // MARK: - Venue Matching

    private func getVenue(for cityName: String) -> WorldCupVenue? {
        // Map city names to venue cities (exact match with WorldCupVenue.swift)
        let cityMapping: [String: String] = [
            "Atlanta": "Atlanta",
            "Boston": "Boston",
            "Dallas": "Dallas",
            "Guadalajara": "Guadalajara",
            "Houston": "Houston",
            "Kansas City": "Kansas City",
            "Los Angeles": "Los Ángeles",  // Con tilde
            "Ciudad de México": "Ciudad de México",
            "Miami": "Miami",
            "Monterrey": "Monterrey",
            "Nueva York / Nueva Jersey": "Nueva York/Nueva Jersey",  // Sin espacios alrededor del slash en WorldCupVenue
            "Philadelphia": "Filadelfia",  // En español en WorldCupVenue
            "San Francisco": "San Francisco Bay Area",  // Nombre completo
            "Seattle": "Seattle",
            "Toronto": "Toronto",
            "Vancouver": "Vancouver"
        ]

        guard let mappedCity = cityMapping[cityName] else {
            print("⚠️ No mapping found for city: \(cityName)")
            print("🔍 Available cities in mapping: \(cityMapping.keys.sorted())")
            return nil
        }

        let venue = WorldCupVenue.allVenues.first { $0.city == mappedCity }
        if venue != nil {
            print("✅ Found venue for \(cityName) -> \(mappedCity)")
        } else {
            print("❌ No venue found for mapped city: \(mappedCity)")
            print("🔍 Available venues: \(WorldCupVenue.allVenues.map { $0.city })")
        }
        return venue
    }

    // MARK: - Session Error Handling

    func handleSessionError(_ error: Error) {
        print("❌ AR Session error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isTrackingReady = false
        }
    }

    // MARK: - Cleanup

    func stopSession() {
        print("🛑 Stopping AR session...")

        // Pause session (this is the blocking operation)
        arView?.session.pause()

        // Clear state on main thread
        DispatchQueue.main.async {
            self.detectedAnchors.removeAll()
            self.detectedCity = nil
            self.selectedVenue = nil
            self.showCityName = false
            self.showNavigationButton = false
            self.showPlayerButton = false
            self.detectedPlayerName = nil
            self.isTrackingReady = false
        }

        print("✅ AR session stopped")
    }
}
