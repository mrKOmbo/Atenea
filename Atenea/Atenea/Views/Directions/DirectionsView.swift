//
//  DirectionsView.swift
//  Atenea
//
//  Created by Claude on 10/14/25.
//

import SwiftUI
import MapKit

// MARK: - Transport Mode
enum TransportMode: String, CaseIterable {
    case driving = "car.fill"
    case walking = "figure.walk"
    case transit = "tram.fill"
    case cycling = "bicycle"
    case rideshare = "figure.wave"

    var title: String {
        switch self {
        case .driving: return "Drive"
        case .walking: return "Walk"
        case .transit: return "Transit"
        case .cycling: return "Cycle"
        case .rideshare: return "Ride"
        }
    }

    var mkDirectionsType: MKDirectionsTransportType? {
        switch self {
        case .driving: return .automobile
        case .walking: return .walking
        case .transit: return .transit
        default: return nil
        }
    }
}

// MARK: - Route Info
struct RouteInfo: Identifiable, Equatable {
    let id = UUID()
    let mode: TransportMode
    let duration: TimeInterval
    let distance: CLLocationDistance
    let route: MKRoute?
    let isFastest: Bool

    var durationText: String {
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return "\(hours)h \(remainingMinutes)min"
        } else {
            return "\(minutes) min"
        }
    }

    var distanceText: String {
        let kilometers = distance / 1000
        return String(format: "%.1f km", kilometers)
    }

    // MARK: - Equatable
    static func == (lhs: RouteInfo, rhs: RouteInfo) -> Bool {
        return lhs.id == rhs.id &&
               lhs.mode == rhs.mode &&
               lhs.duration == rhs.duration &&
               lhs.distance == rhs.distance &&
               lhs.isFastest == rhs.isFastest
    }
}

// MARK: - Modal Height State
enum DirectionsModalHeight {
    case quarter  // 25% - mínimo
    case half     // 50% - medio
    case full     // 92% - completo

    func height(for geometry: GeometryProxy) -> CGFloat {
        switch self {
        case .quarter:
            return geometry.size.height * 0.25
        case .half:
            return geometry.size.height * 0.5
        case .full:
            return geometry.size.height * 0.92
        }
    }
}

// MARK: - Directions View
struct DirectionsView: View {
    @Binding var isPresented: Bool
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let destinationName: String

    // NUEVO: Bindings para pasar polylines al mapa
    @Binding var routePolylines: [MKPolyline]
    @Binding var selectedRouteIndex: Int
    var onClose: (() -> Void)? = nil  // NUEVO: Callback al cerrar

    @StateObject private var viewModel: DirectionsViewModel
    @State private var selectedMode: TransportMode = .driving
    @State private var showTripStarted: Bool = false

    // MARK: - Modal Height Management
    @State private var modalHeight: DirectionsModalHeight = .half
    @GestureState private var dragOffset: CGFloat = 0

    init(
        isPresented: Binding<Bool>,
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        destinationName: String,
        routePolylines: Binding<[MKPolyline]> = .constant([]),
        selectedRouteIndex: Binding<Int> = .constant(0),
        onClose: (() -> Void)? = nil
    ) {
        self._isPresented = isPresented
        self.origin = origin
        self.destination = destination
        self.destinationName = destinationName
        self._routePolylines = routePolylines
        self._selectedRouteIndex = selectedRouteIndex
        self.onClose = onClose
        self._viewModel = StateObject(wrappedValue: DirectionsViewModel(origin: origin, destination: destination))
    }

    var body: some View {
        ZStack {
            // Vista principal de direcciones
            directionsContent

            // Vista de Trip Started (overlay)
            if showTripStarted, let routeInfo = viewModel.routes[selectedMode] {
                TripStartedView(
                    isPresented: $showTripStarted,
                    destination: destinationName,
                    destinationCoordinate: destination,
                    route: routeInfo,
                    onEndTrip: endTrip
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
                .zIndex(1000)
            }
        }
    }

    private var directionsContent: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    Spacer()

                    // Panel de direcciones
                    VStack(spacing: 0) {
                        // Handle - con gesture para arrastrar
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 40, height: 5)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                            .contentShape(Rectangle().size(width: geometry.size.width, height: 30))
                            .gesture(
                                DragGesture()
                                    .updating($dragOffset) { value, state, _ in
                                        state = value.translation.height
                                    }
                                    .onEnded { value in
                                        handleDragEnded(value: value, geometry: geometry)
                                    }
                            )

                        // Contenido scrolleable
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("Directions")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Spacer()

                            Button(action: {
                                // Llamar callback de cierre primero para limpiar estado
                                onClose?()

                                // Cerrar modal
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    isPresented = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(Color(white: 0.2))
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                        // Botones de modo de transporte
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(TransportMode.allCases, id: \.self) { mode in
                                    TransportModeButton(
                                        mode: mode,
                                        isSelected: selectedMode == mode,
                                        routeInfo: viewModel.routes[mode]
                                    ) {
                                        selectedMode = mode
                                        // NUEVO: Actualizar rutas al cambiar modo
                                        updateRoutesForSelectedMode()
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 20)

                        // NUEVO: Selector de rutas alternativas
                        if viewModel.allRoutes.count > 1 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Choose Route")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 20)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(viewModel.allRoutes.enumerated()), id: \.offset) { index, route in
                                            RouteOptionCard(
                                                index: index,
                                                route: route,
                                                isSelected: viewModel.selectedRouteIndex == index
                                            ) {
                                                viewModel.selectRoute(at: index)
                                                selectedRouteIndex = index
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.bottom, 16)
                        }

                        // Lista de ubicaciones
                        VStack(spacing: 0) {
                            // Origen
                            LocationRow(
                                icon: "location.fill",
                                iconColor: .blue,
                                title: "My Location",
                                isOrigin: true
                            )

                            // Línea conectora
                            HStack {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 2, height: 30)
                                    .padding(.leading, 33)

                                Spacer()
                            }

                            // Destino
                            LocationRow(
                                icon: "mappin.circle.fill",
                                iconColor: .orange,
                                title: destinationName,
                                isOrigin: false
                            )

                            // Botón Add Stop
                            Button(action: {
                                // Agregar parada intermedia
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)

                                    Text("Add Stop")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.blue)

                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                        }
                        .background(Color(white: 0.12))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                        // Opciones de tiempo
                        HStack(spacing: 12) {
                            TimeOptionButton(title: "Now", isSelected: true) {
                                // Cambiar tiempo
                            }

                            TimeOptionButton(title: "Avoid", isSelected: false) {
                                // Opciones de evitar
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                        // Información de la ruta seleccionada
                        if let routeInfo = viewModel.routes[selectedMode] {
                            RouteDetailView(routeInfo: routeInfo)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                        } else if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.bottom, 20)
                        }

                        // Botón GO
                        Button(action: {
                            // Iniciar navegación
                            startNavigation()
                        }) {
                            Text("GO")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.green)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: modalHeight.height(for: geometry) - dragOffset)
                    .background(Color.black)
                    .clipShape(
                        RoundedCorner(radius: 30, corners: [.topLeft, .topRight])
                    )
                }
            }
        }
        .onAppear {
            viewModel.calculateRoutes()
        }
        .onChange(of: viewModel.allRoutes.count) { _ in
            // NUEVO: Actualizar polylines cuando cambian las rutas
            routePolylines = viewModel.allRoutes.compactMap { $0.route?.polyline }
            print("🛣️ Polylines actualizadas: \(routePolylines.count) rutas")
        }
        .onChange(of: viewModel.selectedRouteIndex) { newIndex in
            // NUEVO: Actualizar índice de ruta seleccionada
            selectedRouteIndex = newIndex
            print("🎯 Ruta seleccionada: \(newIndex)")
        }
    }

    private func updateRoutesForSelectedMode() {
        // Actualizar allRoutes basado en el modo seleccionado
        // DirectionsViewModel ya tiene esta lógica
        // Solo necesitamos disparar el cambio
        print("🔄 Modo de transporte cambiado a: \(selectedMode.title)")
    }

    // MARK: - Drag Handling

    private func handleDragEnded(value: DragGesture.Value, geometry: GeometryProxy) {
        let translation = value.translation.height
        let velocity = value.predictedEndTranslation.height - value.translation.height

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            // Si arrastra hacia abajo más de 100pts o con velocidad alta
            if translation > 100 || velocity > 500 {
                switch modalHeight {
                case .full:
                    modalHeight = .half
                case .half:
                    modalHeight = .quarter  // Bajar a quarter en lugar de cerrar
                case .quarter:
                    // NO hacer nada - evitar cierre accidental
                    break
                }
            }
            // Si arrastra hacia arriba más de 100pts o con velocidad alta
            else if translation < -100 || velocity < -500 {
                switch modalHeight {
                case .quarter:
                    modalHeight = .half
                case .half:
                    modalHeight = .full
                case .full:
                    // Ya está en full, no hacer nada
                    break
                }
            }
        }
    }

    private func startNavigation() {
        // Mostrar vista de Trip Started
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showTripStarted = true
        }
    }

    private func endTrip() {
        // Cerrar vista de trip started y volver al mapa
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showTripStarted = false
            isPresented = false
        }
    }
}

// MARK: - Transport Mode Button
struct TransportModeButton: View {
    let mode: TransportMode
    let isSelected: Bool
    let routeInfo: RouteInfo?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mode.rawValue)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))

                if let info = routeInfo {
                    Text(info.durationText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                } else {
                    Text(mode.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                }
            }
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(white: 0.25) : Color(white: 0.15))
            )
        }
    }
}

// MARK: - Location Row
struct LocationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let isOrigin: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 17))
                .foregroundColor(.white)

            Spacer()

            Button(action: {
                // Opciones de ubicación
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Time Option Button
struct TimeOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(white: isSelected ? 0.25 : 0.15))
                )
        }
    }
}

// MARK: - Route Detail View
struct RouteDetailView: View {
    let routeInfo: RouteInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(routeInfo.durationText)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("• \(routeInfo.distanceText)")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))

                if routeInfo.isFastest {
                    Text("Fastest")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.2))
                        )
                }

                Spacer()
            }

            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)

                Text("Low emission zone")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))

                Button(action: {
                    // Mostrar más información
                }) {
                    Text("More")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Route Option Card
struct RouteOptionCard: View {
    let index: Int
    let route: RouteInfo
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Route \(index + 1)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.7))

                    if route.isFastest {
                        Text("FASTEST")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.2))
                            )
                    }

                    Spacer()
                }

                Text(route.durationText)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))

                Text(route.distanceText)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .white.opacity(0.6))
            }
            .padding(12)
            .frame(width: 140)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(white: 0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    DirectionsView(
        isPresented: .constant(true),
        origin: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
        destination: CLLocationCoordinate2D(latitude: 19.4420, longitude: -99.1270),
        destinationName: "Estadio Azteca"
    )
}
