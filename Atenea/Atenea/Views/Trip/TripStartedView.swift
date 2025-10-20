//
//  TripStartedView.swift
//  Atenea
//
//  Vista especial que aparece cuando el usuario inicia un viaje
//

import SwiftUI
import MapKit
import ActivityKit

struct TripStartedView: View {
    @Binding var isPresented: Bool
    let destination: String
    let destinationCoordinate: CLLocationCoordinate2D
    let route: RouteInfo
    let onEndTrip: () -> Void

    @State private var showContent: Bool = false
    @State private var pulseAnimation: Bool = false
    @State private var progress: Double = 0.0
    @State private var showActiveNavigation: Bool = false
    @State private var activity: Activity<NavigationActivityAttributes>?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fondo oscuro sólido
                Color.black
                    .ignoresSafeArea()

                // Gradiente sutil para profundidad
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color(hex: "#00D084").opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .overlay(
                    // Efecto de pulso sutil
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "#00D084").opacity(0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 400
                            )
                        )
                        .scaleEffect(pulseAnimation ? 1.5 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.3)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false), value: pulseAnimation)
                )

                VStack(spacing: 0) {
                    // Header con botón cerrar
                    HStack {
                        Spacer()

                        Button(action: {
                            stopLiveActivity()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                onEndTrip()
                                isPresented = false
                            }
                        }) {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                    Spacer()

                    // Contenido principal
                    VStack(spacing: 32) {
                        // Icono animado grande
                        ZStack {
                            // Anillo exterior
                            Circle()
                                .stroke(Color(hex: "#00D084").opacity(0.2), lineWidth: 4)
                                .frame(width: 160, height: 160)

                            // Anillo medio pulsante
                            Circle()
                                .stroke(Color(hex: "#00D084").opacity(0.4), lineWidth: 3)
                                .frame(width: 140, height: 140)
                                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                                .opacity(pulseAnimation ? 0.5 : 1.0)

                            // Círculo interior con gradiente
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#C8FF00"), Color(hex: "#00D084")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .shadow(color: Color(hex: "#00D084").opacity(0.5), radius: 20, x: 0, y: 10)

                            // Icono de navegación
                            Image(systemName: route.mode.rawValue)
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .scaleEffect(showContent ? 1.0 : 0.5)
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: showContent)

                        // Título
                        VStack(spacing: 12) {
                            Text("Trip Started!")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(showContent ? 1.0 : 0.8)
                                .opacity(showContent ? 1.0 : 0.0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: showContent)

                            Text("Navigating to")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .opacity(showContent ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.4).delay(0.4), value: showContent)

                            Text(destination)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(Color(hex: "#C8FF00"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .opacity(showContent ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.4).delay(0.5), value: showContent)
                        }

                        // Información del viaje
                        HStack(spacing: 40) {
                            TripInfoCard(
                                icon: "clock.fill",
                                title: "ETA",
                                value: route.durationText,
                                color: Color(hex: "#00D084")
                            )

                            TripInfoCard(
                                icon: "location.fill",
                                title: "Distance",
                                value: route.distanceText,
                                color: Color(hex: "#C8FF00")
                            )
                        }
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.5).delay(0.6), value: showContent)
                    }

                    Spacer()

                    // Botones de acción
                    VStack(spacing: 16) {
                        // Botón de iniciar navegación
                        Button(action: {
                            // Iniciar navegación activa
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showActiveNavigation = true
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 20, weight: .semibold))

                                Text("Start Navigation")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#C8FF00"), Color(hex: "#00D084")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .disabled(route.route == nil)

                        // Botón de cancelar viaje
                        Button(action: {
                            stopLiveActivity()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                onEndTrip()
                                isPresented = false
                            }
                        }) {
                            Text("End Trip")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20) + 20)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 50)
                    .animation(.easeOut(duration: 0.5).delay(0.7), value: showContent)
                }
            }
        }
        .fullScreenCover(isPresented: $showActiveNavigation) {
            // Vista de navegación activa
            if let mkRoute = route.route {
                ActiveNavigationView(
                    isPresented: $showActiveNavigation,
                    destination: destination,
                    route: mkRoute,
                    destinationCoordinate: destinationCoordinate
                )
            }
        }
        .onAppear {
            withAnimation {
                showContent = true
                pulseAnimation = true
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Iniciar Live Activity
            startLiveActivity()
        }
        .onDisappear {
            // Detener Live Activity solo si no vamos a navegación activa
            if !showActiveNavigation {
                stopLiveActivity()
            }
        }
    }

    // MARK: - Live Activity Methods

    private func startLiveActivity() {
        print("🔷 Intentando iniciar Live Activity...")

        // Verificar que Live Activities estén habilitadas
        let authInfo = ActivityAuthorizationInfo()
        print("🔷 Estado de autorización: \(authInfo.areActivitiesEnabled)")

        guard authInfo.areActivitiesEnabled else {
            print("⚠️ Live Activities no están habilitadas - verifica en Configuración > Notificaciones")
            return
        }

        // Crear atributos
        let attributes = NavigationActivityAttributes(destinationName: destination)

        // Crear estado inicial con información del viaje
        let initialState = NavigationActivityAttributes.ContentState(
            currentInstruction: "Trip started to \(destination)",
            distanceRemaining: route.distance,
            timeRemaining: route.duration
        )

        print("🔷 Datos del viaje - Distancia: \(route.distance)m, Tiempo: \(route.duration)s")

        do {
            // Iniciar la actividad
            let content = ActivityContent(state: initialState, staleDate: nil)
            activity = try Activity<NavigationActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            print("✅ Live Activity iniciada exitosamente")
            print("✅ Activity ID: \(activity?.id ?? "unknown")")

            // Verificar actividades activas
            let activeCount = Activity<NavigationActivityAttributes>.activities.count
            print("✅ Actividades activas: \(activeCount)")
        } catch {
            print("❌ Error al iniciar Live Activity: \(error)")
            print("❌ Error detalles: \(error.localizedDescription)")
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
}

// MARK: - Trip Info Card
struct TripInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 140, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    TripStartedView(
        isPresented: .constant(true),
        destination: "Estadio Azteca",
        destinationCoordinate: CLLocationCoordinate2D(latitude: 19.3029, longitude: -99.1506),
        route: RouteInfo(
            mode: .driving,
            duration: 1800,
            distance: 15000,
            route: nil,
            isFastest: true
        ),
        onEndTrip: {}
    )
}
