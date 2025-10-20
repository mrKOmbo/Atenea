//
//  ARPosterView.swift
//  Atenea
//
//  Created by Emilio Cruz Vargas on 07/10/25.
//

import SwiftUI
import ARKit
import RealityKit
import MapKit
import Contacts

struct ARPosterView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var arViewModel = ARPosterViewModel()
    @ObservedObject var collectionManager: StickerCollectionManager
    @ObservedObject var arService = ARStickerCollectionService.shared
    @State private var isDismissing = false
    @State private var pulseAnimation: Bool = false
    @State private var showAlbum = false
    var onVenueDetected: ((WorldCupVenue) -> Void)?
    var onStickersCollected: ((WorldCupVenue) -> Void)?

    var body: some View {
        ZStack {
            // AR View
            ARPosterViewContainer(arViewModel: arViewModel)
                .ignoresSafeArea()
                .onAppear {
                    print("📱 ARPosterViewContainer appeared")
                }

            // Loading indicator
            if !arViewModel.isTrackingReady {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)

                    Text("Inicializando AR...")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Preparando detección de posters")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(32)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            // Overlay UI
            VStack {
                // Header
                headerView

                Spacer()

                // City Name Display
                if arViewModel.showCityName, let venue = arViewModel.selectedVenue {
                    cityNameView(venue: venue)
                        .padding(.bottom, 180)
                        .transition(.scale.combined(with: .opacity))
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )
                        .onAppear {
                            pulseAnimation = true
                        }
                        .onDisappear {
                            pulseAnimation = false
                        }
                }

                // Botones de acción para sedes
                if arViewModel.showNavigationButton, let venue = arViewModel.selectedVenue {
                    VStack(spacing: 16) {
                        // Botón de coleccionar stickers
                        collectStickersButton(venue: venue)
                            .transition(.scale.combined(with: .opacity))

                        // Botón de navegación
                        navigationButton(venue: venue)
                            .transition(.scale.combined(with: .opacity))
                    }
                    .padding(.bottom, 100)
                }

                // Botón de acción para jugadores
                if arViewModel.showPlayerButton, let playerName = arViewModel.detectedPlayerName {
                    addPlayerToAlbumButton(playerName: playerName)
                        .padding(.bottom, 100)
                        .transition(.scale.combined(with: .opacity))
                }

                // Instructions
                if arViewModel.isTrackingReady && !arViewModel.showCityName && !arViewModel.showNavigationButton && !arViewModel.showPlayerButton {
                    instructionsView
                        .padding(.bottom, 50)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showAlbum) {
            PaniniAlbumView(
                isPresented: $showAlbum,
                initialPage: arViewModel.albumTargetPage,
                shouldAnimateToPage: true  // 🎬 true = animación | false = salto directo
            )
            .onDisappear {
                dismiss()
            }
        }
        .onDisappear {
            arViewModel.stopSession()
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            Button {
                dismissView()
            } label: {
                Image(systemName: isDismissing ? "hourglass" : "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white, .black.opacity(0.3))
                    .shadow(radius: 10)
            }
            .disabled(isDismissing)

            Spacer()

            Text("Mundial 2026 AR")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())

            Spacer()

            // Placeholder for balance
            Color.clear
                .frame(width: 32, height: 32)
        }
        .padding()
    }

    // MARK: - City Name View

    private func cityNameView(venue: WorldCupVenue) -> some View {
        ZStack {
            // Anillo pulsante exterior - Color primario de la sede
            RoundedRectangle(cornerRadius: 30)
                .stroke(venue.primaryColor, lineWidth: 3)
                .frame(width: 340, height: 140)
                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                .opacity(pulseAnimation ? 0.0 : 0.8)
                .animation(
                    Animation.easeOut(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: pulseAnimation
                )

            // Segundo anillo pulsante (desfasado) - Color secundario de la sede
            RoundedRectangle(cornerRadius: 30)
                .stroke(venue.secondaryColor, lineWidth: 2)
                .frame(width: 340, height: 140)
                .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                .opacity(pulseAnimation ? 0.0 : 0.6)
                .animation(
                    Animation.easeOut(duration: 1.5)
                        .delay(0.3)
                        .repeatForever(autoreverses: false),
                    value: pulseAnimation
                )

            // Contenido principal
            VStack(spacing: 10) {
                Text("🏟️ SEDE MUNDIAL 2026")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())

                Text(venue.city)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.5), radius: 10)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        venue.primaryColor,
                        venue.secondaryColor
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(25)
            .shadow(color: venue.primaryColor.opacity(0.7), radius: 20, x: 0, y: 5)
        }
    }

    // MARK: - Collect Stickers Button

    private func collectStickersButton(venue: WorldCupVenue) -> some View {
        Button {
            collectStickers(for: venue)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Agregar al Álbum")
                        .font(.headline)

                    Text("Colecciona esta sede")
                        .font(.caption)
                        .opacity(0.8)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .foregroundColor(.white)
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#00D084"),
                        Color(hex: "#00A067")
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color(hex: "#00D084").opacity(0.6), radius: 15, x: 0, y: 5)
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Navigation Button

    private func navigationButton(venue: WorldCupVenue) -> some View {
        Button {
            navigateToVenue(venue)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "map.fill")
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ver en el Mapa")
                        .font(.headline)

                    Text(venue.name)
                        .font(.caption)
                        .opacity(0.8)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
            }
            .foregroundColor(.white)
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [venue.primaryColor, venue.secondaryColor]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: venue.primaryColor.opacity(0.6), radius: 15, x: 0, y: 5)
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Add Player to Album Button

    private func addPlayerToAlbumButton(playerName: String) -> some View {
        Button {
            openAlbum()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.rectangle.stack")
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Agregar al Álbum")
                        .font(.headline)

                    Text("Ver álbum de \(playerName)")
                        .font(.caption)
                        .opacity(0.8)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .foregroundColor(.white)
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#8B4513"),
                        Color(hex: "#654321")
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color(hex: "#8B4513").opacity(0.6), radius: 15, x: 0, y: 5)
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Instructions View

    private var instructionsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "camera.viewfinder")
                .font(.title2)
                .foregroundColor(.white)

            Text("Apunta a un poster del Mundial 2026")
                .font(.subheadline)
                .foregroundColor(.white)

            Text("Mantén el poster en el centro de la pantalla")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }

    // MARK: - Helper Methods

    private func navigateToVenue(_ venue: WorldCupVenue) {
        guard !isDismissing else { return }
        isDismissing = true

        print("🎯 Navegando a la sede: \(venue.city)")

        // Stop AR session
        arViewModel.stopSession()

        // Llamar al callback y cerrar
        onVenueDetected?(venue)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("✅ Cerrando AR y navegando al mapa")
            self.dismiss()
        }
    }

    private func dismissView() {
        guard !isDismissing else { return }
        isDismissing = true

        print("🚪 User requested AR view dismissal")

        // Stop AR session immediately on main thread - it's fast enough
        arViewModel.stopSession()

        // Small delay to ensure cleanup completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("✅ Dismissing AR view")
            self.dismiss()
        }
    }

    private func collectStickers(for venue: WorldCupVenue) {
        guard !isDismissing else { return }
        isDismissing = true

        print("📸 Coleccionando stickers para: \(venue.name)")

        // Coleccionar stickers usando el servicio AR
        arService.collectStickerForVenue(venue, collectionManager: collectionManager)

        // Detener sesión AR
        arViewModel.stopSession()

        // Llamar callback para navegar al álbum con animación
        onStickersCollected?(venue)

        // Cerrar vista AR
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("✅ Cerrando AR y navegando al álbum")
            self.dismiss()
        }
    }

    private func openAlbum() {
        guard !isDismissing else { return }
        isDismissing = true

        print("📖 Abriendo álbum 2022")

        // Detener sesión AR
        arViewModel.stopSession()

        // Abrir álbum
        showAlbum = true
    }
}

// MARK: - AR View Container

struct ARPosterViewContainer: UIViewRepresentable {
    @ObservedObject var arViewModel: ARPosterViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Setup AR session through view model
        arViewModel.setupARSession(in: arView)

        // Set delegate
        arView.session.delegate = context.coordinator

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Updates handled by view model
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        print("🧹 Dismantling AR UIView")

        // Detener y limpiar la sesión
        uiView.session.pause()

        // Remover todos los anclajes
        uiView.scene.anchors.removeAll()

        // Limpiar el delegate
        uiView.session.delegate = nil

        print("✅ AR UIView dismantled")
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: arViewModel)
    }

    class Coordinator: NSObject, ARSessionDelegate {
        let viewModel: ARPosterViewModel

        init(viewModel: ARPosterViewModel) {
            self.viewModel = viewModel
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            viewModel.handleARFrame(frame)
        }

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                viewModel.handleAnchorAdded(anchor)
            }
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                viewModel.handleAnchorUpdated(anchor)
            }
        }

        func session(_ session: ARSession, didFailWithError error: Error) {
            viewModel.handleSessionError(error)
        }
    }
}

// MARK: - Venue Navigation View

struct VenueNavigationView: View {
    @Environment(\.dismiss) var dismiss
    let venue: WorldCupVenue

    var body: some View {
        NavigationView {
            ZStack {
                // Usar el WorldCupMapView existente enfocado en la sede
                VenueMapView(venue: venue)
                    .ignoresSafeArea()

                // Overlay con información de la sede
                VStack {
                    Spacer()

                    VStack(spacing: 16) {
                        // Información de la sede
                        VStack(spacing: 8) {
                            Text(venue.name)
                                .font(.title2.bold())
                                .foregroundColor(.white)

                            Text("\(venue.city), \(venue.country)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))

                            HStack(spacing: 16) {
                                Label(venue.capacity, systemImage: "person.3.fill")
                                Label(venue.inauguration, systemImage: "calendar")
                            }
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)

                        // Botón para abrir en Apple Maps
                        Button(action: {
                            openInMaps()
                        }) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Abrir en Apple Maps")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [venue.primaryColor, venue.secondaryColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func openInMaps() {
        let coordinate = venue.coordinate
        // Create a placemark for the venue
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: [
            CNPostalAddressStreetKey: venue.name,
            CNPostalAddressCityKey: venue.city,
            CNPostalAddressCountryKey: venue.country
        ])
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = venue.name

        // Open driving directions in Apple Maps
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// Vista de mapa enfocado en una sede específica
struct VenueMapView: View {
    let venue: WorldCupVenue
    @State private var cameraPosition: MapCameraPosition

    init(venue: WorldCupVenue) {
        self.venue = venue
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: venue.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        ))
    }

    var body: some View {
        Map(position: $cameraPosition) {
            Annotation(venue.city, coordinate: venue.coordinate) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [venue.primaryColor, venue.secondaryColor]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: venue.primaryColor.opacity(0.6), radius: 10)

                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 50, height: 50)

                    Image(systemName: "soccerball")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }
}

#Preview {
    ARPosterView(collectionManager: StickerCollectionManager())
}
