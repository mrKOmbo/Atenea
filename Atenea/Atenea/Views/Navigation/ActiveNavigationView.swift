//
//  ActiveNavigationView.swift
//  Atenea
//
//  Vista de navegación activa estilo Apple Maps
//

import SwiftUI
import MapKit
import CoreLocation

struct ActiveNavigationView: View {
    @Binding var isPresented: Bool
    let destination: String
    let route: MKRoute
    let destinationCoordinate: CLLocationCoordinate2D

    @StateObject private var navigationManager = NavigationManager()
    @State private var mapRegion: MKCoordinateRegion
    @State private var showEndNavigationAlert: Bool = false

    init(
        isPresented: Binding<Bool>,
        destination: String,
        route: MKRoute,
        destinationCoordinate: CLLocationCoordinate2D
    ) {
        self._isPresented = isPresented
        self.destination = destination
        self.route = route
        self.destinationCoordinate = destinationCoordinate

        // Inicializar región del mapa centrada en la ruta
        let center = route.polyline.coordinate
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        self._mapRegion = State(initialValue: MKCoordinateRegion(center: center, span: span))
    }

    var body: some View {
        ZStack {
            // Mapa a pantalla completa
            NativeMapView(
                region: $mapRegion,
                venues: [],
                onVenueSelected: { _ in },
                onUserLocationLongPress: { _ in },
                shouldFollowUserWithHeading: true,
                mapMode: .driving,
                routePolylines: [route.polyline],
                selectedRouteIndex: 0,
                selectedDestination: destinationCoordinate
            )
            .ignoresSafeArea()

            // Overlay UI
            VStack(spacing: 0) {
                // Banner superior con instrucciones
                navigationInstructionBanner
                    .padding(.top, 60)

                Spacer()

                // Panel inferior con información
                navigationBottomPanel
            }

            // Botón de finalizar navegación (esquina superior derecha)
            VStack {
                HStack {
                    Spacer()

                    Button(action: {
                        showEndNavigationAlert = true
                    }) {
                        Circle()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 60)

                    Spacer()
                        .frame(width: 0)
                }

                Spacer()
            }
        }
        .alert("End Navigation", isPresented: $showEndNavigationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End", role: .destructive) {
                endNavigation()
            }
        } message: {
            Text("Are you sure you want to end navigation?")
        }
        .alert("Arrived!", isPresented: $navigationManager.hasArrived) {
            Button("Done") {
                endNavigation()
            }
        } message: {
            Text("You have arrived at \(destination)")
        }
        .onAppear {
            // Iniciar navegación
            navigationManager.startNavigation(route: route, destination: destinationCoordinate, destinationName: destination)
        }
        .onDisappear {
            navigationManager.stopNavigation()
        }
    }

    // MARK: - Subviews

    private var navigationInstructionBanner: some View {
        VStack(spacing: 0) {
            if let currentStep = navigationManager.currentStep {
                HStack(spacing: 16) {
                    // Icono de maniobra
                    Image(systemName: currentStep.instructionIcon)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(Color(hex: "#00D084"))
                        .frame(width: 60)

                    // Instrucción
                    VStack(alignment: .leading, spacing: 4) {
                        if currentStep.distance > 0 {
                            Text(formatDistance(currentStep.distance))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Text(currentStep.instructions)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.85))
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 16)
            } else {
                // Placeholder si no hay paso actual
                HStack {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(Color(hex: "#00D084"))

                    Text("Continue")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.85))
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 16)
            }
        }
    }

    private var navigationBottomPanel: some View {
        VStack(spacing: 0) {
            // Información de ETA y distancia
            HStack(spacing: 0) {
                // ETA
                VStack(spacing: 4) {
                    Text(formatTimeRemaining(navigationManager.timeRemaining))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("ETA")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .background(Color.white.opacity(0.2))
                    .frame(height: 50)

                // Distancia restante
                VStack(spacing: 4) {
                    Text(formatDistance(navigationManager.distanceRemaining))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Distance")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .background(Color.white.opacity(0.2))
                    .frame(height: 50)

                // Destino
                VStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "#C8FF00"))

                    Text(destination)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 30)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.black.opacity(0.9))
                    .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: -10)
            )
        }
    }

    // MARK: - Helper Methods

    private func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            let km = meters / 1000
            return String(format: "%.1f km", km)
        }
    }

    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "< 1 min"
        }
    }

    private func endNavigation() {
        navigationManager.stopNavigation()
        isPresented = false
    }
}

#Preview {
    ActiveNavigationView(
        isPresented: .constant(true),
        destination: "Estadio Azteca",
        route: MKRoute(),
        destinationCoordinate: CLLocationCoordinate2D(latitude: 19.3029, longitude: -99.1506)
    )
}
