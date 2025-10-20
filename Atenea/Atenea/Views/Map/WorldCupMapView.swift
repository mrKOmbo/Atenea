// WorldCupMapView.swift
// Atenea
//
// Created by Emilio Cruz Vargas on 10/10/25.
//

import SwiftUI
import MapKit

enum FocusMode {
    case northAmerica
    case mexico
    case usa
    case canada
    case userLocation
}

struct WorldCupMapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchManager = LocationSearchManager() // NUEVO: Manager de búsqueda
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var selectedTab: Int
    @ObservedObject var collectionManager: StickerCollectionManager
    @Binding var lastCollectedVenue: WorldCupVenue?
    @Binding var showCollectionAnimation: Bool

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
            span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
        )
    )

    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
    )

    @State private var focusMode: FocusMode = .northAmerica
    @State private var isMenuOpen = false
    @State private var selectedVenue: WorldCupVenue?
    @State private var selectedMapMode: MapMode = .explore
    @State private var scheduledMatch: ScheduledMatch?
    @State private var showVenuesView = false
    @State private var showScheduleModal = false
    @State private var selectedVenueForSchedule: String?
    @State private var reservations: [VenueReservation] = []  // NUEVO: Lista de reservaciones
    @State private var showVenueDetail = false
    @State private var showARView = false
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var isLoadingLookAround = false
    @State private var showLookAroundPreview = false
    @State private var searchText: String = ""
    @State private var selectedCategory: String?
    @State private var showChatSearch = false // Controla cuándo mostrar el chat de búsqueda con IA
    @State private var userLocationLookAroundAvailable = false // Look Around disponible en ubicación del usuario
    @State private var isCheckingLookAround = false // Verificando disponibilidad de Look Around
    @State private var userLocationLookAroundScene: MKLookAroundScene? // Scene para ubicación del usuario
    @State private var showUserLocationLookAround = false // Mostrar Look Around de ubicación del usuario
    @State private var showShareLocationSheet = false // Mostrar sheet para compartir ubicación
    @State private var shareLocationCoordinate: CLLocationCoordinate2D? // Coordenadas a compartir

    // NUEVO: Estados para sistema de direcciones
    @State private var showDirections = false
    @State private var directionsDestination: CLLocationCoordinate2D?
    @State private var directionsDestinationName: String = ""
    @State private var routePolylines: [MKPolyline] = []
    @State private var selectedRouteIndex: Int = 0
    @State private var selectedDestinationCoordinate: CLLocationCoordinate2D?

    // NUEVO: Estados para búsqueda con autocomplete
    @State private var showLocationSearch = false
    @State private var locationSearchQuery: String = ""

    // NUEVO: Estados para marcadores de recomendaciones (restaurantes, cafés, etc.)
    @State private var recommendationMarkers: [RecommendationMarker] = []
    @State private var isSearchingPlaces = false

    let venues = WorldCupVenue.allVenues

    // Coordenadas para enfocar México (centro de las 3 sedes mexicanas)
    let mexicoRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 21.8853, longitude: -102.2916),
        span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)
    )

    // Coordenadas para enfocar USA (centro de las sedes estadounidenses)
    let usaRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.0902, longitude: -95.7129),
        span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 25)
    )

    // Coordenadas para enfocar Canadá (centro de las sedes canadienses)
    let canadaRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 49.8951, longitude: -97.1384),
        span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15)
    )

    var body: some View {
        ZStack {
            // Mapa nativo con UIKit - incluye indicador azul con giroscopio automático
            NativeMapView(
                region: $mapRegion,
                venues: venues,
                onVenueSelected: { venue in
                    selectedVenue = venue

                    // Desactivar seguimiento de usuario al seleccionar una sede
                    focusMode = .northAmerica

                    // Animar el mapa hacia la sede seleccionada
                    withAnimation(.easeInOut(duration: 0.6)) {
                        mapRegion = MKCoordinateRegion(
                            center: CLLocationCoordinate2D(
                                latitude: venue.coordinate.latitude - 0.015,
                                longitude: venue.coordinate.longitude
                            ),
                            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                        )
                    }

                    // Cargar Look Around para esta sede
                    loadLookAroundScene(for: venue)

                    // Abrir panel de detalles automáticamente
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showLookAroundPreview = false // Ocultar Look Around preview mientras se muestra el panel
                        showVenueDetail = true
                    }
                },
                onUserLocationLongPress: { coordinate in
                    // Guardar coordenadas y mostrar sheet de compartir
                    shareLocationCoordinate = coordinate
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        showShareLocationSheet = true
                    }
                },
                shouldFollowUserWithHeading: focusMode == .userLocation,
                mapMode: selectedMapMode,
                // NUEVO: Parámetros para direcciones
                routePolylines: routePolylines,
                selectedRouteIndex: selectedRouteIndex,
                onMapTap: { coordinate in
                    handleMapTap(coordinate: coordinate)
                },
                selectedDestination: selectedDestinationCoordinate,
                // NUEVO: Parámetros para marcadores de recomendaciones
                recommendationMarkers: recommendationMarkers
            )
            .ignoresSafeArea()

            // Contenido superpuesto sobre el mapa
            VStack(alignment: .leading, spacing: 0) {
                // Panel de búsqueda superior - OCULTO cuando se muestran direcciones
                if !showDirections {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            // Barra de búsqueda completa - FUNCIONAL
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 18))

                                TextField(LocalizedString("map.search"), text: $searchText)
                                    .foregroundColor(.black)
                                    .font(.system(size: 16))
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .onChange(of: searchText) { oldValue, newValue in
                                        // Actualizar región de búsqueda
                                        if let userLocation = locationManager.location?.coordinate {
                                            searchManager.updateSearchRegion(center: userLocation)
                                        }
                                        // Actualizar query en el manager
                                        searchManager.searchQuery = newValue
                                    }

                                // Botón de limpiar
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                        searchManager.searchQuery = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 18))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(22)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)

                            // Botón de menú hamburguesa (derecha)
                            Button(action: {
                                withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                                    isMenuOpen.toggle()
                                }
                            }) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: isMenuOpen ? "xmark" : "line.3.horizontal")
                                            .foregroundColor(.black)
                                            .font(.system(size: 18, weight: .semibold))
                                            .rotationEffect(.degrees(isMenuOpen ? 90 : 0))
                                            .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: isMenuOpen)
                                    )
                                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    .scaleEffect(isMenuOpen ? 1.1 :
                                                    1.0)
                                    .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: isMenuOpen)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 50)

                        // Resultados de búsqueda - aparecen debajo del buscador
                        if !searchText.isEmpty && !searchManager.searchResults.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(Array(searchManager.searchResults.prefix(6))) { result in
                                    Button(action: {
                                        // Usar selectResult del manager para obtener coordenadas
                                        searchManager.selectResult(result) { coordinate, name in
                                            guard let coord = coordinate else { return }

                                            // Limpiar rutas anteriores
                                            self.routePolylines = []
                                            self.selectedRouteIndex = 0

                                            // Seleccionar ubicación
                                            self.selectedDestinationCoordinate = coord
                                            self.directionsDestination = coord
                                            self.directionsDestinationName = name

                                            // NO centrar aquí - esperar a que las rutas se calculen
                                            // El centrado se hará automáticamente en onChange(routePolylines)

                                            // Limpiar búsqueda
                                            searchText = ""
                                            searchManager.searchQuery = ""

                                            // Abrir direcciones
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                                showDirections = true
                                            }
                                        }
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "mappin.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.blue)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(result.title)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.black)
                                                    .lineLimit(1)

                                                if !result.subtitle.isEmpty {
                                                    Text(result.subtitle)
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.gray)
                                                        .lineLimit(1)
                                                }
                                            }

                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }

                                    if result.id != searchManager.searchResults.prefix(6).last?.id {
                                        Divider()
                                            .padding(.leading, 48)
                                    }
                                }
                            }
                            .frame(maxHeight: 400)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Botones de categoría scrolleables - OCULTOS cuando hay búsqueda
                        if searchText.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // Botón "Limpiar" - solo visible cuando hay marcadores
                                    if !recommendationMarkers.isEmpty {
                                        CategoryButton(
                                            title: LocalizedString("map.clear"),
                                            icon: "xmark.circle.fill",
                                            color: .red,
                                            isSelected: false
                                        ) {
                                            clearRecommendationMarkers()
                                        }
                                    }

                                    CategoryButton(
                                        title: LocalizedString("map.suggestions"),
                                        icon: "sparkles",
                                        color: .purple,
                                        isSelected: selectedCategory == "popular"
                                    ) {
                                        selectedCategory = "popular"
                                        isMenuOpen = false // Cerrar menú hamburguesa
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                            showChatSearch = true
                                        }
                                    }

                                    CategoryButton(
                                        title: LocalizedString("map.dinner"),
                                        icon: "fork.knife",
                                        color: .orange,
                                        isSelected: selectedCategory == "dinner"
                                    ) {
                                        if selectedCategory == "dinner" {
                                            // Si ya está seleccionado, limpiar
                                            clearRecommendationMarkers()
                                        } else {
                                            selectedCategory = "dinner"
                                            isMenuOpen = false
                                            searchPlacesByCategory("restaurants")
                                        }
                                    }

                                    CategoryButton(
                                        title: LocalizedString("map.coffee"),
                                        icon: "cup.and.saucer.fill",
                                        color: .brown,
                                        isSelected: selectedCategory == "coffee"
                                    ) {
                                        if selectedCategory == "coffee" {
                                            // Si ya está seleccionado, limpiar
                                            clearRecommendationMarkers()
                                        } else {
                                            selectedCategory = "coffee"
                                            isMenuOpen = false
                                            searchPlacesByCategory("coffee")
                                        }
                                    }

                                    CategoryButton(
                                        title: LocalizedString("map.bars"),
                                        icon: "wineglass.fill",
                                        color: .purple,
                                        isSelected: selectedCategory == "bars"
                                    ) {
                                        if selectedCategory == "bars" {
                                            // Si ya está seleccionado, limpiar
                                            clearRecommendationMarkers()
                                        } else {
                                            selectedCategory = "bars"
                                            isMenuOpen = false
                                            searchPlacesByCategory("bars")
                                        }
                                    }

                                    CategoryButton(
                                        title: LocalizedString("map.hotels"),
                                        icon: "bed.double.fill",
                                        color: .blue,
                                        isSelected: selectedCategory == "hotels"
                                    ) {
                                        if selectedCategory == "hotels" {
                                            // Si ya está seleccionado, limpiar
                                            clearRecommendationMarkers()
                                        } else {
                                            selectedCategory = "hotels"
                                            isMenuOpen = false
                                            searchPlacesByCategory("hotels")
                                        }
                                    }

                                    CategoryButton(
                                        title: LocalizedString("map.museums"),
                                        icon: "building.columns.fill",
                                        color: .red,
                                        isSelected: selectedCategory == "museums"
                                    ) {
                                        if selectedCategory == "museums" {
                                            // Si ya está seleccionado, limpiar
                                            clearRecommendationMarkers()
                                        } else {
                                            selectedCategory = "museums"
                                            isMenuOpen = false
                                            searchPlacesByCategory("museums")
                                        }
                                    }

                                    CategoryButton(
                                        title: LocalizedString("map.gyms"),
                                        icon: "figure.strengthtraining.traditional",
                                        color: .green,
                                        isSelected: selectedCategory == "gyms"
                                    ) {
                                        if selectedCategory == "gyms" {
                                            // Si ya está seleccionado, limpiar
                                            clearRecommendationMarkers()
                                        } else {
                                            selectedCategory = "gyms"
                                            isMenuOpen = false
                                            searchPlacesByCategory("gyms")
                                        }
                                    }

                                    CategoryButton(
                                        title: LocalizedString("map.parks"),
                                        icon: "tree.fill",
                                        color: .green,
                                        isSelected: selectedCategory == "parks"
                                    ) {
                                        if selectedCategory == "parks" {
                                            // Si ya está seleccionado, limpiar
                                            clearRecommendationMarkers()
                                        } else {
                                            selectedCategory = "parks"
                                            isMenuOpen = false
                                            searchPlacesByCategory("parks")
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }

                Spacer()

                // Look Around interactivo flotante para ubicación del usuario - JUSTO DEBAJO
                if !showDirections && showUserLocationLookAround, let scene = userLocationLookAroundScene, let userLocation = locationManager.location {
                    TappedLocationLookAroundView(
                        scene: scene,
                        coordinate: userLocation.coordinate,
                        onClose: {
                            withAnimation {
                                showUserLocationLookAround = false
                                userLocationLookAroundScene = nil
                            }
                        }
                    )
                    .padding(.top, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Look Around interactivo flotante para venues - JUSTO DEBAJO
                if !showDirections && showLookAroundPreview, let scene = lookAroundScene, let venue = selectedVenue {
                    InteractiveLookAroundView(
                        scene: scene,
                        venue: venue,
                        onClose: {
                            withAnimation {
                                showLookAroundPreview = false
                                selectedVenue = nil
                            }
                        },
                        onShowDetails: {
                            withAnimation {
                                showVenueDetail = true
                            }
                        }
                    )
                    .padding(.top, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                // Botones flotantes en la parte inferior
                VStack {
                    Spacer()

                    HStack {
                        // Botón de binoculares (izquierda)
                        if userLocationLookAroundAvailable && focusMode == .userLocation {
                            Button(action: {
                                openLookAroundForUserLocation()
                            }) {
                                Image(systemName: "binoculars.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.leading, 20)
                            .transition(.scale.combined(with: .opacity))
                        }

                        Spacer()

                        // Stack vertical de botones (derecha)
                        VStack(spacing: 16) {
                            // Botón de AR para detectar posters
                            Button(action: {
                                withAnimation {
                                    showARView = true
                                }
                                print("📹 Abriendo AR para detectar posters")
                            }) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(hex: "#7B00FF"), Color(hex: "#9D00FF")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                                    .shadow(color: Color(hex: "#7B00FF").opacity(0.5), radius: 10, x: 0, y: 5)
                            }

                            // Botón de ubicación
                            Button(action: {
                                toggleFocusMode()
                            }) {
                                Image(systemName: "location.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.bottom, showDirections ? 470 : 180)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showDirections)
                }
            }
            .padding(.top) // <-- ✨ CORRECCIÓN APLICADA AQUÍ

            // Modal deslizable tipo Google Maps - OCULTO cuando se muestran direcciones
            if !isMenuOpen && !showDirections {
                DraggableBottomSheet(
                    locationManager: locationManager,
                    selectedTab: $selectedTab,
                    venues: venues,
                    scheduledMatch: scheduledMatch,
                    reservations: $reservations  // NUEVO: Pasar reservaciones
                )
                .id(scheduledMatch?.id)  // NUEVO: Forzar actualización cuando cambie el partido
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Menú de perfil deslizable desde la derecha
            if isMenuOpen {
                ZStack(alignment: .trailing) {
                    // Overlay oscuro para cerrar el menú con animación suave
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                isMenuOpen = false
                            }
                        }
                        .transition(.opacity)

                    ProfileMenuPanel(isMenuOpen: $isMenuOpen, selectedMapMode: $selectedMapMode, scheduledMatch: $scheduledMatch, showVenuesView: $showVenuesView)
                        .transition(.move(edge: .trailing))
                }
                .zIndex(100)
            }

            // Modal de selección de sedes
            if showVenuesView {
                ZStack {
                    // Fondo que bloquea toda interacción
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            // No hacer nada - bloquear clics al mapa
                        }

                    VenuesSelectionView(
                        isPresented: $showVenuesView,
                        onVenueSelected: { venue in
                            selectedVenueForSchedule = venue
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                showVenuesView = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                showScheduleModal = true
                            }
                        }
                    )
                }
                .zIndex(200)
                .transition(.opacity)
            }

            // Modal de agendamiento
            if showScheduleModal {
                ZStack {
                    // Fondo que bloquea toda interacción
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            // No hacer nada - bloquear clics al mapa
                        }

                    ScheduleMatchModal(
                        isPresented: $showScheduleModal,
                        scheduledMatch: $scheduledMatch,
                        preselectedVenue: selectedVenueForSchedule,
                        onMatchScheduled: {
                            // Agregar la reservación a la lista
                            if let match = scheduledMatch {
                                addReservation(from: match)
                            }

                            // Cerrar el menú para mostrar el DraggableBottomSheet con el partido agendado
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                isMenuOpen = false
                            }
                        }
                    )
                }
                .zIndex(300)
                .transition(.opacity)
            }

            // Modal de búsqueda con IA
            if showChatSearch {
                AISearchView(
                    isPresented: $showChatSearch,
                    selectedCategory: selectedCategory,
                    onNavigateToLocation: navigateToLocation,
                    onShowDirections: showDirectionsToPlace
                )
                .zIndex(1000)
            }

            // Vista detallada de sede
            if showVenueDetail, let venue = selectedVenue {
                VenueDetailView(venue: venue, isPresented: $showVenueDetail) {
                    // Al cerrar, volver a mostrar el Look Around preview
                    withAnimation {
                        showLookAroundPreview = true
                    }
                }
                .zIndex(500) // Por encima de todo para permitir interacción
            }

            // Sheet bonito para compartir ubicación
            if showShareLocationSheet, let coordinate = shareLocationCoordinate {
                ShareLocationSheet(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    isPresented: $showShareLocationSheet
                )
                .zIndex(600) // Por encima de todo
            }

            // NUEVO: Modal de direcciones
            if showDirections,
               let destination = directionsDestination,
               let userLocation = locationManager.location?.coordinate {
                DirectionsView(
                    isPresented: $showDirections,
                    origin: userLocation,
                    destination: destination,
                    destinationName: directionsDestinationName,
                    routePolylines: $routePolylines,
                    selectedRouteIndex: $selectedRouteIndex,
                    onClose: {
                        // Limpiar todo inmediatamente cuando se presiona X
                        print("🧹 Limpiando marcador y rutas...")
                        routePolylines = []
                        selectedDestinationCoordinate = nil
                        directionsDestination = nil
                        directionsDestinationName = ""
                        selectedRouteIndex = 0
                    }
                )
                .id("\(destination.latitude)-\(destination.longitude)")  // NUEVO: Forzar recreación cuando cambia destino
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(700) // Por encima de todo
                .onChange(of: routePolylines) { oldValue, newValue in
                    // Centrar mapa cuando se calculen las rutas
                    if !newValue.isEmpty {
                        // Esperar un poco para que el modal se anime y las rutas se dibujen
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            centerMapOnSelectedRoute()
                        }
                    }
                }
                .onChange(of: selectedRouteIndex) { oldValue, newValue in
                    // Centrar mapa cuando se cambie la ruta seleccionada
                    centerMapOnSelectedRoute()
                }
            }


        }
        .fullScreenCover(isPresented: $showARView) {
            ARPosterView(
                collectionManager: collectionManager,
                onVenueDetected: { venue in
                    // Cuando se detecta una sede en AR, navegar automáticamente a ella
                    print("🎯 Sede detectada en AR: \(venue.city)")
                    navigateToVenueFromAR(venue)
                },
                onStickersCollected: { venue in
                    // Cuando se coleccionen stickers, navegar al álbum
                    print("📸 Stickers coleccionados, navegando al álbum")
                    lastCollectedVenue = venue
                    showCollectionAnimation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedTab = 2 // Tab del álbum
                    }
                }
            )
            .onAppear {
                print("📹 AR View appeared!")
            }
        }
        .onAppear {
            // Cargar reservaciones guardadas
            loadReservations()

            // Iniciar actualizaciones de ubicación y heading (giroscopio)
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            print("🧭 Iniciando heading y ubicación al abrir la vista")

            // Inicializar ubicación del usuario automáticamente
            initializeUserLocation()
        }
    }

    // Función para detectar el país del usuario basándose en sus coordenadas
    func detectUserCountry() -> FocusMode {
        guard let location = locationManager.location else {
            return .northAmerica
        }

        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        // Rangos aproximados de coordenadas para cada país
        // México: latitud 14° a 32°, longitud -118° a -86°
        if latitude >= 14.0 && latitude <= 32.0 && longitude >= -118.0 && longitude <= -86.0 {
            return .mexico
        }
        // Canadá: latitud 41° a 83°, longitud -141° a -52°
        else if latitude >= 41.0 && latitude <= 83.0 && longitude >= -141.0 && longitude <= -52.0 {
            return .canada
        }
        // USA: latitud 24° a 49°, longitud -125° a -66°
        else if latitude >= 24.0 && latitude <= 49.0 && longitude >= -125.0 && longitude <= -66.0 {
            return .usa
        }

        // Por defecto, vista de Norteamérica
        return .northAmerica
    }

    // Función para alternar entre los modos de enfoque
    func toggleFocusMode() {
        switch focusMode {
        case .northAmerica:
            // Primera presión: detectar el país del usuario y enfocar ahí
            if locationManager.checkAuthorization() {
                let userCountry = detectUserCountry()
                focusMode = userCountry

                withAnimation(.easeInOut(duration: 0.8)) {
                    switch userCountry {
                    case .mexico:
                        mapRegion = mexicoRegion
                        print("🇲🇽 Enfocando a México")
                    case .usa:
                        mapRegion = usaRegion
                        print("🇺🇸 Enfocando a USA")
                    case .canada:
                        mapRegion = canadaRegion
                        print("🇨🇦 Enfocando a Canadá")
                    default:
                        // Si no puede detectar, ir a Norteamérica
                        mapRegion = MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
                            span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
                        )
                    }
                }
            } else if locationManager.authorizationStatus == .notDetermined {
                // Solicitar permisos
                locationManager.requestPermission()
                print("⏳ Esperando permisos de ubicación...")
            } else {
                // Permisos denegados, ir a México por defecto
                focusMode = .mexico
                withAnimation(.easeInOut(duration: 0.8)) {
                    mapRegion = mexicoRegion
                }
                print("❌ Permisos denegados. Ve a Configuración → Atenea → Ubicación")
            }

        case .mexico, .usa, .canada:
            // Segunda presión: ir a la ubicación exacta del usuario
            if locationManager.checkAuthorization() {
                // Ya tenemos permisos, obtener ubicación
                focusMode = .userLocation
                locationManager.requestLocation()
                centerOnUserLocation()
            } else if locationManager.authorizationStatus == .notDetermined {
                // Permisos no determinados, el LocationManager ya los solicitó en init()
                // Solo necesitamos obtener la ubicación cuando se autorice
                focusMode = .userLocation
                print("⏳ Esperando autorización de permisos...")

                // Dar tiempo para que el usuario responda al diálogo
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if self.locationManager.checkAuthorization() {
                        self.locationManager.requestLocation()
                        self.centerOnUserLocation()
                    } else {
                        print("❌ Usuario no autorizó permisos")
                        self.focusMode = .northAmerica
                    }
                }
            } else {
                // Permisos denegados
                print("❌ Permisos denegados. Ve a Configuración → Atenea → Ubicación")
                print("💡 Permitir 'Mientras se usa la app'")
            }

        case .userLocation:
            // Tercera presión: vuelve a vista de Norteamérica
            focusMode = .northAmerica
            withAnimation(.easeInOut(duration: 0.8)) {
                mapRegion = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
                    span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
                )
            }
            print("🌎 Volviendo a vista de Norteamérica")
        }
    }

    // Helper para centrar en ubicación del usuario
    private func centerOnUserLocation() {
        // Asegurar que heading esté activo para mostrar el conito direccional
        locationManager.startUpdatingHeading()

        // Cambiar al modo de seguimiento del usuario
        focusMode = .userLocation

        // Verificar disponibilidad de Look Around en la ubicación del usuario
        checkLookAroundAvailabilityForUserLocation()

        // El mapa automáticamente seguirá al usuario con heading ahora
        print("🧭 Modo de seguimiento con heading activado")
    }

    // Inicializar ubicación del usuario automáticamente
    private func initializeUserLocation() {
        // Verificar si tenemos permisos
        if locationManager.checkAuthorization() {
            print("📍 Iniciando tracking de ubicación y heading...")
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading() // CRÍTICO: Activar giroscopio

            // NO activar focusMode automáticamente - solo esperar a que el usuario presione el botón
            print("✅ Ubicación lista - esperando acción del usuario")
        } else {
            print("⏳ Esperando permisos de ubicación...")
            // Intentar solicitar permisos si no están determinados
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestPermission()

                // Reintentar después de solicitar permisos
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.initializeUserLocation()
                }
            }
        }
    }

    // FUNCIÓN PÚBLICA: Navegar a cualquier ubicación desde el chat
    // Esta función será llamada cuando se haga clic en "View on Map" o en nombres de lugares
    func navigateToLocation(coordinate: CLLocationCoordinate2D, placeName: String, zoomLevel: Double = 0.05) {
        print("🗺️ Navegando a: \(placeName)")

        // Cerrar el chat si está abierto
        showChatSearch = false

        // Desactivar seguimiento del usuario
        focusMode = .northAmerica

        // Animar el mapa hacia la ubicación
        withAnimation(.easeInOut(duration: 0.8)) {
            mapRegion = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: zoomLevel, longitudeDelta: zoomLevel)
            )
        }
    }

    // NUEVA FUNCIÓN: Mostrar direcciones a un lugar desde Claude
    func showDirectionsToPlace(coordinate: CLLocationCoordinate2D, placeName: String) {
        print("🗺️ Mostrando direcciones a: \(placeName)")

        // Limpiar rutas anteriores si hay un destino diferente
        if let currentDestination = directionsDestination,
           currentDestination.latitude != coordinate.latitude || currentDestination.longitude != coordinate.longitude {
            routePolylines = []
            selectedRouteIndex = 0
        }

        // Configurar nuevo destino
        self.selectedDestinationCoordinate = coordinate
        self.directionsDestination = coordinate
        self.directionsDestinationName = placeName

        // NO centrar aquí - esperar a que las rutas se calculen
        // El centrado se hará automáticamente en onChange(routePolylines)

        // Si el modal ya está abierto, no hay delay. Si no, delay para animación
        if showDirections {
            // Modal ya abierto, actualización inmediata
            print("🔄 Actualizando destino en modal existente")
        } else {
            // Abrir modal de direcciones con un pequeño delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    self.showDirections = true
                }
            }
        }
    }

    // NUEVA FUNCIÓN: Buscar lugares por categoría y mostrar marcadores
    func searchPlacesByCategory(_ category: String) {
        print("🔍 Buscando lugares de categoría: \(category)")

        // Verificar que tenemos ubicación del usuario
        guard let userLocation = locationManager.location else {
            print("⚠️ No se pudo obtener la ubicación del usuario")
            return
        }

        // Limpiar marcadores anteriores
        recommendationMarkers = []
        isSearchingPlaces = true

        // Configurar búsqueda según la categoría
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = category

        // Crear región de 10 km alrededor de la ubicación del usuario
        // 10 km = 10,000 metros
        // 1 grado de latitud ≈ 111 km
        // Para 10 km: 10 / 111 ≈ 0.09 grados
        let searchRadius: CLLocationDistance = 10000 // 10 km en metros
        let regionSpan = searchRadius / 111000 // Convertir metros a grados

        let searchRegion = MKCoordinateRegion(
            center: userLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: regionSpan * 2, longitudeDelta: regionSpan * 2)
        )

        searchRequest.region = searchRegion
        print("📍 Buscando en un radio de 10 km desde: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")

        // Limitar a puntos de interés
        searchRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: pointOfInterestCategories(for: category))

        let search = MKLocalSearch(request: searchRequest)

        search.start { response, error in
            DispatchQueue.main.async {
                self.isSearchingPlaces = false

                if let error = error {
                    print("❌ Error buscando lugares: \(error.localizedDescription)")
                    return
                }

                guard let response = response else {
                    print("⚠️ No se encontraron resultados para: \(category)")
                    return
                }

                // Convertir resultados a marcadores y filtrar por distancia exacta de 10 km
                let userLocation = self.locationManager.location!
                let markers = response.mapItems.compactMap { mapItem -> RecommendationMarker? in
                    guard let name = mapItem.name else { return nil }

                    let coordinate = mapItem.location.coordinate
                    let placeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

                    // Calcular distancia desde la ubicación del usuario
                    let distance = userLocation.distance(from: placeLocation)

                    // Filtrar: solo incluir lugares dentro de 10 km (10,000 metros)
                    guard distance <= 10000 else {
                        return nil
                    }

                    let address = [
                        mapItem.placemark.thoroughfare,
                        mapItem.placemark.locality
                    ].compactMap { $0 }.joined(separator: ", ")

                    return RecommendationMarker(
                        coordinate: coordinate,
                        name: name,
                        category: category,
                        address: address.isEmpty ? nil : address
                    )
                }

                // Limitar a 20 resultados y convertir a array
                let filteredMarkers = Array(markers.prefix(20))

                self.recommendationMarkers = filteredMarkers
                print("✅ Encontrados \(filteredMarkers.count) lugares de \(category) dentro de 10 km")

                // Si hay marcadores, ajustar el mapa para mostrarlos todos
                if !filteredMarkers.isEmpty {
                    self.centerMapOnMarkers()
                }
            }
        }
    }

    // Función helper para obtener categorías de POI según el tipo de búsqueda
    private func pointOfInterestCategories(for category: String) -> [MKPointOfInterestCategory] {
        switch category.lowercased() {
        case "dinner", "restaurant", "restaurants":
            return [.restaurant, .foodMarket]
        case "coffee", "café", "cafe":
            return [.cafe, .bakery]
        case "bars", "bar":
            return [.brewery, .winery, .nightlife]
        case "hotels", "hotel":
            return [.hotel]
        case "museums", "museum":
            return [.museum]
        case "gyms", "gym", "fitness":
            return [.fitnessCenter]
        case "parks", "park":
            return [.park, .nationalPark]
        default:
            return []
        }
    }

    // Función para centrar el mapa mostrando todos los marcadores
    private func centerMapOnMarkers() {
        guard !recommendationMarkers.isEmpty else { return }

        let coordinates = recommendationMarkers.map { $0.coordinate }

        // Calcular los límites
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0

        // Calcular centro y span
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let spanLat = (maxLat - minLat) * 1.5 // 1.5x para padding
        let spanLon = (maxLon - minLon) * 1.5

        let newRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: max(spanLat, 0.05), longitudeDelta: max(spanLon, 0.05))
        )

        withAnimation(.easeInOut(duration: 0.6)) {
            mapRegion = newRegion
        }
    }

    // Función para limpiar todos los marcadores de recomendaciones
    func clearRecommendationMarkers() {
        print("🧹 Limpiando marcadores de recomendaciones")
        withAnimation {
            recommendationMarkers = []
            selectedCategory = nil
        }
    }

    // Función para cargar Look Around Scene
    private func loadLookAroundScene(for venue: WorldCupVenue) {
        isLoadingLookAround = true
        lookAroundScene = nil
        showLookAroundPreview = false

        Task {
            let request = MKLookAroundSceneRequest(coordinate: venue.coordinate)

            do {
                let scene = try await request.scene

                await MainActor.run {
                    if let scene = scene {
                        self.lookAroundScene = scene
                        self.isLoadingLookAround = false

                        // Auto-mostrar Look Around interactivo después de cargar
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                self.showLookAroundPreview = true
                            }
                        }
                    } else {
                        self.isLoadingLookAround = false
                        print("⚠️ Look Around no disponible para esta sede")
                    }
                }
            } catch {
                print("❌ Error al cargar Look Around: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoadingLookAround = false
                }
            }
        }
    }

    // Función para cargar Look Around para la ubicación del usuario
    private func loadLookAroundForUserLocation(coordinate: CLLocationCoordinate2D) {
        userLocationLookAroundScene = nil
        showUserLocationLookAround = false

        Task {
            let request = MKLookAroundSceneRequest(coordinate: coordinate)

            do {
                let scene = try await request.scene

                await MainActor.run {
                    if let scene = scene {
                        self.userLocationLookAroundScene = scene

                        // Auto-mostrar Look Around interactivo
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                self.showUserLocationLookAround = true
                            }
                        }
                    } else {
                        print("⚠️ Look Around no disponible en tu ubicación")
                    }
                }
            } catch {
                print("❌ Error al cargar Look Around: \(error.localizedDescription)")
            }
        }
    }

    // Verificar disponibilidad de Look Around en la ubicación del usuario
    private func checkLookAroundAvailabilityForUserLocation() {
        guard let userLocation = locationManager.location else {
            print("⚠️ No hay ubicación del usuario para verificar Look Around")
            return
        }

        guard !isCheckingLookAround else {
            print("⏳ Ya se está verificando disponibilidad de Look Around")
            return
        }

        isCheckingLookAround = true

        Task {
            let request = MKLookAroundSceneRequest(coordinate: userLocation.coordinate)

            do {
                let scene = try await request.scene

                await MainActor.run {
                    if scene != nil {
                        self.userLocationLookAroundAvailable = true
                        print("✅ Look Around disponible en tu ubicación")
                    } else {
                        self.userLocationLookAroundAvailable = false
                        print("❌ Look Around no disponible en tu ubicación")
                    }
                    self.isCheckingLookAround = false
                }
            } catch {
                await MainActor.run {
                    self.userLocationLookAroundAvailable = false
                    self.isCheckingLookAround = false
                    print("⚠️ Error verificando Look Around: \(error)")
                }
            }
        }
    }

    // Abrir Look Around para la ubicación del usuario
    private func openLookAroundForUserLocation() {
        guard let userLocation = locationManager.location else {
            print("⚠️ No hay ubicación del usuario")
            return
        }

        print("👀 Abriendo Look Around para tu ubicación")
        loadLookAroundForUserLocation(coordinate: userLocation.coordinate)
    }

    // Función para navegar a una sede detectada desde AR
    private func navigateToVenueFromAR(_ venue: WorldCupVenue) {
        print("🎯 Navegando a sede detectada en AR: \(venue.city)")

        // Establecer la sede seleccionada
        selectedVenue = venue

        // Cambiar modo de enfoque
        focusMode = .northAmerica

        // Animar el mapa hacia la sede con un zoom más cercano
        withAnimation(.easeInOut(duration: 1.0)) {
            mapRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: venue.coordinate.latitude - 0.015,
                    longitude: venue.coordinate.longitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
            )
        }

        // Cargar Look Around para esta sede
        loadLookAroundScene(for: venue)

        // Abrir panel de detalles automáticamente después de un breve delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.showLookAroundPreview = false // Ocultar Look Around preview mientras se muestra el panel
                self.showVenueDetail = true
            }
        }
    }

    // NUEVO: Función para manejar tap en el mapa
    private func handleMapTap(coordinate: CLLocationCoordinate2D) {
        print("🗺️ Tap en mapa detectado: \(coordinate.latitude), \(coordinate.longitude)")

        // Actualizar la región de búsqueda del manager
        searchManager.updateSearchRegion(center: coordinate)

        // Realizar geocodificación inversa para obtener el nombre del lugar
        searchManager.reverseGeocode(coordinate: coordinate) { placeName in
            guard let name = placeName else {
                print("⚠️ No se pudo obtener nombre del lugar")
                return
            }

            print("📍 Lugar seleccionado: \(name)")

            // Establecer destino y mostrar modal de direcciones
            DispatchQueue.main.async {
                // Limpiar rutas anteriores
                self.routePolylines = []
                self.selectedRouteIndex = 0

                self.selectedDestinationCoordinate = coordinate
                self.directionsDestination = coordinate
                self.directionsDestinationName = name

                // NO centrar aquí - esperar a que las rutas se calculen
                // El centrado se hará automáticamente en onChange(routePolylines)

                // Abrir modal de direcciones
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    self.showDirections = true
                }
            }
        }
    }

    // MARK: - Route Centering

    /// Centra el mapa para mostrar ambos puntos (origen y destino)
    /// Ajusta el centro hacia arriba para compensar el modal que ocupa la parte inferior
    private func centerMapBetweenPoints(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {
        // Calcular el centro entre los dos puntos
        let centerLat = (origin.latitude + destination.latitude) / 2
        let centerLon = (origin.longitude + destination.longitude) / 2

        // Calcular el span necesario para incluir ambos puntos
        let latDelta = abs(origin.latitude - destination.latitude)
        let lonDelta = abs(origin.longitude - destination.longitude)

        // Agregar padding generoso para que los puntos no estén en los bordes
        let paddedLatDelta = max(latDelta * 2.8, 0.015) // Mínimo 0.015 para lugares muy cercanos
        let paddedLonDelta = max(lonDelta * 2.8, 0.015)

        let span = MKCoordinateSpan(
            latitudeDelta: paddedLatDelta,
            longitudeDelta: paddedLonDelta
        )

        // AJUSTE CRÍTICO: Mover el centro hacia arriba (norte) para compensar el modal
        // El modal en estado "half" ocupa ~50% de la pantalla inferior
        // Movemos el centro hacia arriba aproximadamente 20% del span para que
        // la ruta quede visible en la parte superior
        let offsetLatitude = centerLat + (span.latitudeDelta * 0.25)
        let adjustedCenter = CLLocationCoordinate2D(latitude: offsetLatitude, longitude: centerLon)

        let region = MKCoordinateRegion(center: adjustedCenter, span: span)

        // Animar el cambio de región
        withAnimation(.easeInOut(duration: 0.8)) {
            mapRegion = region
        }

        print("🗺️ Mapa centrado entre origen y destino (ajustado para modal)")
    }

    /// Ajusta la región del mapa para mostrar toda la ruta seleccionada
    /// Ajusta el centro hacia arriba para compensar el modal que ocupa la parte inferior
    private func centerMapOnSelectedRoute() {
        guard !routePolylines.isEmpty,
              selectedRouteIndex < routePolylines.count else {
            print("⚠️ No hay rutas para centrar")
            return
        }

        let selectedRoute = routePolylines[selectedRouteIndex]
        let rect = selectedRoute.boundingMapRect

        // Convertir MKMapRect a MKCoordinateRegion
        let region = MKCoordinateRegion(rect)

        // Agregar padding MUY generoso para que la ruta no esté en los bordes
        // Aumentado el padding considerando que el modal ocupa parte de la pantalla
        let span = MKCoordinateSpan(
            latitudeDelta: region.span.latitudeDelta * 3.0,
            longitudeDelta: region.span.longitudeDelta * 3.0
        )

        // AJUSTE CRÍTICO: Mover el centro hacia arriba (norte) para compensar el modal
        // El modal en estado "half" ocupa ~50% de la pantalla inferior
        // Movemos el centro hacia arriba aproximadamente 30% del span para que
        // la ruta quede visible en la parte superior de la pantalla
        let offsetLatitude = region.center.latitude + (span.latitudeDelta * 0.30)
        let adjustedCenter = CLLocationCoordinate2D(latitude: offsetLatitude, longitude: region.center.longitude)

        let paddedRegion = MKCoordinateRegion(
            center: adjustedCenter,
            span: span
        )

        // Animar el cambio de región
        withAnimation(.easeInOut(duration: 0.8)) {
            mapRegion = paddedRegion
        }

        print("🗺️ Mapa centrado en ruta seleccionada (índice: \(selectedRouteIndex), ajustado para modal)")
    }

    // MARK: - Reservations Persistence

    private func loadReservations() {
        if let data = UserDefaults.standard.data(forKey: "savedReservations"),
           let decoded = try? JSONDecoder().decode([VenueReservation].self, from: data) {
            reservations = decoded
            print("📚 Cargadas \(reservations.count) reservaciones")
        } else {
            reservations = []
            print("📚 No hay reservaciones guardadas")
        }
    }

    private func saveReservations() {
        if let encoded = try? JSONEncoder().encode(reservations) {
            UserDefaults.standard.set(encoded, forKey: "savedReservations")
            print("💾 Guardadas \(reservations.count) reservaciones")
        }
    }

    func addReservation(from scheduledMatch: ScheduledMatch) {
        // Convertir ScheduledMatch a VenueReservation
        let reservation = VenueReservation(
            venueName: scheduledMatch.venue,
            venueCity: extractCity(from: scheduledMatch.venue),
            date: scheduledMatch.date,
            seatNumber: scheduledMatch.seats,
            status: statusToString(scheduledMatch.status)
        )

        reservations.append(reservation)
        saveReservations()
        print("✅ Reservación agregada: \(reservation.venueName)")
    }

    private func extractCity(from venueName: String) -> String {
        // Extraer la ciudad del nombre del estadio
        // Formato: "Estadio Nombre - Ciudad"
        let components = venueName.split(separator: "-")
        if components.count > 1 {
            return String(components[1].trimmingCharacters(in: .whitespaces))
        }
        return venueName
    }

    private func statusToString(_ status: String) -> String {
        switch status.lowercased() {
        case "confirmado": return "confirmed"
        case "pendiente": return "pending"
        case "cancelado": return "cancelled"
        default: return "confirmed"
        }
    }
}

// Marcador personalizado para cada sede con gradiente diagonal
struct VenueMarker: View {
    let venue: WorldCupVenue
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Sombra del marcador (más grande cuando está seleccionado)
                Circle()
                    .fill(Color.black.opacity(isSelected ? 0.4 : 0.3))
                    .frame(width: isSelected ? 48 : 44, height: isSelected ? 48 : 44)
                    .blur(radius: isSelected ? 6 : 4)
                    .offset(y: 2)

                // Marcador principal con gradiente lineal diagonal
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [venue.primaryColor, venue.secondaryColor]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: isSelected ? 48 : 44, height: isSelected ? 48 : 44)

                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 4 : 3.5)
                        .frame(width: isSelected ? 48 : 44, height: isSelected ? 48 : 44)

                    // Ícono - cambiar a mappin cuando está seleccionado
                    Image(systemName: isSelected ? "mappin.circle.fill" : "soccerball")
                        .font(.system(size: isSelected ? 22 : 18, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 3)
                }
                .shadow(color: venue.primaryColor.opacity(isSelected ? 0.9 : 0.7), radius: isSelected ? 16 : 12)
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

            // Etiqueta con el nombre de la ciudad
            Text(venue.city)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [venue.primaryColor, venue.secondaryColor]),
                                startPoint: .topLeading,  // Esquina superior izquierda
                                endPoint: .bottomTrailing  // Esquina inferior derecha
                            )
                        )
                        .shadow(color: venue.primaryColor.opacity(0.5), radius: 6)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .offset(y: 10)
        }
    }
}

struct CountryLegend: View {
    let country: String
    let flag: String
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Text(flag)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(country)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("\(count) sedes")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Botón de enfoque con estados dinámicos
struct FocusButton: View {
    @Binding var focusMode: FocusMode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icono dinámico según el modo
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text(titleText)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(subtitleText)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: shadowColor, radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var iconName: String {
        switch focusMode {
        case .northAmerica:
            return "mappin.circle.fill"
        case .mexico, .usa, .canada:
            return "location.fill"
        case .userLocation:
            return "mappin.circle.fill"
        }
    }

    private var titleText: String {
        switch focusMode {
        case .northAmerica:
            return "Tu País"
        case .mexico:
            return "Mi Ubicación"
        case .usa:
            return "Mi Ubicación"
        case .canada:
            return "Mi Ubicación"
        case .userLocation:
            return "Vista General"
        }
    }

    private var subtitleText: String {
        switch focusMode {
        case .northAmerica:
            return "Ir a tu país"
        case .mexico:
            return "¿Dónde estoy?"
        case .usa:
            return "¿Dónde estoy?"
        case .canada:
            return "¿Dónde estoy?"
        case .userLocation:
            return "Volver a Norteamérica"
        }
    }

    private var gradientColors: [Color] {
        switch focusMode {
        case .northAmerica:
            return [Color(hex: "#0072CE"), Color(hex: "#00A9E0")]  // Azul
        case .mexico:
            return [Color(hex: "#00A651"), Color(hex: "#EF4135")]  // Bandera de México
        case .usa:
            return [Color(hex: "#B22234"), Color(hex: "#3C3B6E")]  // Bandera de USA
        case .canada:
            return [Color(hex: "#FF0000"), Color(hex: "#FFFFFF")]  // Bandera de Canadá
        case .userLocation:
            return [Color(hex: "#0072CE"), Color(hex: "#00A9E0")]  // Azul
        }
    }

    private var shadowColor: Color {
        switch focusMode {
        case .northAmerica:
            return Color(hex: "#0072CE").opacity(0.5)
        case .mexico:
            return Color(hex: "#00A651").opacity(0.5)
        case .usa:
            return Color(hex: "#B22234").opacity(0.5)
        case .canada:
            return Color(hex: "#FF0000").opacity(0.5)
        case .userLocation:
            return Color(hex: "#0072CE").opacity(0.5)
        }
    }
}

// Tarjeta de transporte horizontal con efecto liquid glass
struct TransportCard: View {
    let transport: TransportType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Ícono con efecto glass
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    transport.color.opacity(0.3),
                                    transport.color.opacity(0.15)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(transport.color.opacity(0.4), lineWidth: 1.5)
                        )
                        .shadow(color: transport.color.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: transport.icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(transport.color)
                }

                // Nombre del transporte
                VStack(spacing: 4) {
                    Text(transport.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    // Indicador de selección
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(transport.color)
                            .shadow(color: transport.color.opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .frame(width: 120)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                // Efecto liquid glass para las tarjetas
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(isSelected ? 0.25 : 0.15),
                                    Color.white.opacity(isSelected ? 0.15 : 0.08),
                                    Color.white.opacity(isSelected ? 0.2 : 0.12)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Brillo superior
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.15),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isSelected ? transport.color.opacity(0.8) : Color.white.opacity(0.3),
                                isSelected ? transport.color.opacity(0.5) : Color.white.opacity(0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2.5 : 1.5
                    )
                    .shadow(color: isSelected ? transport.color.opacity(0.5) : Color.clear, radius: 8, x: 0, y: 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Vista previa de transportes que siempre está visible
struct TransportPeekView: View {
    @State private var isExpanded = false
    @State private var selectedTransport: TransportType?
    @State private var searchText: String = ""

    var filteredTransports: [TransportType] {
        if searchText.isEmpty {
            return TransportType.allCases
        } else {
            return TransportType.allCases.filter { transport in
                transport.rawValue.localizedCaseInsensitiveContains(searchText) ||
                transport.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Header con buscador - siempre visible
                    VStack(spacing: 16) {
                        // Indicador de arrastre con efecto glass
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.3)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 40, height: 5)
                            .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 1)
                            .padding(.top, 12)

                        // Campo de búsqueda con efecto liquid glass
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 18, weight: .semibold))

                            TextField("Buscar transporte", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .placeholder(when: searchText.isEmpty) {
                                    Text("Buscar transporte")
                                        .foregroundColor(.white.opacity(0.5))
                                }

                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.system(size: 18))
                                }
                            } else {
                                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            // Efecto liquid glass para el campo de búsqueda
                            ZStack {
                                // Material de vidrio
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)

                                // Gradiente semi-transparente
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.2),
                                                Color.white.opacity(0.1),
                                                Color.white.opacity(0.15)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                // Brillo superior
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.2),
                                                Color.clear
                                            ]),
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.4),
                                                Color.white.opacity(0.2)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    .background(
                        Color.white.opacity(0.05)
                    )
                    .onTapGesture {
                        if searchText.isEmpty {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isExpanded.toggle()
                            }
                        }
                    }

                    // Contenido expandible
                    if isExpanded {
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 0.5)

                            // ScrollView horizontal de transportes
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(filteredTransports) { transport in
                                        TransportCard(
                                            transport: transport,
                                            isSelected: selectedTransport == transport
                                        ) {
                                            selectedTransport = transport
                                            print("Seleccionado: \(transport.rawValue)")
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                            }
                            .frame(height: 200)
                            .padding(.top, 8)

                            Spacer(minLength: 0)
                        }
                        .frame(height: geometry.size.height * 0.4)
                        .background(
                            Color.white.opacity(0.03)
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Spacer para el safe area inferior
                    Color.clear
                        .frame(height: geometry.safeAreaInsets.bottom)
                        .background(Color.white.opacity(0.05))
                }
                .background(
                    // Efecto liquid glass para todo el panel
                    ZStack {
                        // Material de vidrio con blur
                        Rectangle()
                            .fill(.ultraThinMaterial)

                        // Gradiente de fondo
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.12)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        // Brillo superior
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.15),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .center
                        )
                    }
                )
                .overlay(
                    // Borde superior brillante
                    VStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.2)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                        Spacer()
                    }
                )
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: -10)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: -3)
            }
        }
    }
}

// Extensión para aplicar corner radius solo en ciertas esquinas
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }

    // Extensión para placeholder personalizado en TextField
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Vista de Look Around para ubicaciones tocadas (sin venue)
struct TappedLocationLookAroundView: View {
    let scene: MKLookAroundScene
    let coordinate: CLLocationCoordinate2D
    let onClose: () -> Void

    @State private var showFullScreen = false

    var body: some View {
        // Vista Look Around compacta - sin GeometryReader
        ZStack {
            // UIKit Look Around - Interactivo desde el primer momento
            LookAroundUIKitWrapper(scene: scene)
                .frame(height: 220) // MÁS COMPACTO
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
                .onTapGesture {
                    showFullScreen = true
                }

            // Solo botón de cerrar en esquina superior derecha
            VStack {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                    }
                    .padding(10)
                }
                Spacer()
            }
            .frame(height: 220)
        }
        .frame(height: 220)
        .padding(.horizontal, 16)
        .fullScreenCover(isPresented: $showFullScreen) {
            LookAroundView(coordinate: coordinate, venueName: "Ubicación")
        }
    }
}

// Vista de Look Around interactiva flotante tipo Apple Maps
struct InteractiveLookAroundView: View {
    let scene: MKLookAroundScene
    let venue: WorldCupVenue
    let onClose: () -> Void
    let onShowDetails: () -> Void

    @State private var showFullScreen = false

    var body: some View {
        // Vista Look Around compacta - sin GeometryReader
        ZStack {
            // UIKit Look Around - Interactivo desde el primer momento
            LookAroundUIKitWrapper(scene: scene)
                .frame(height: 220) // MÁS COMPACTO
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
                .onTapGesture {
                    showFullScreen = true
                }

            // Información de la sede (esquina superior izquierda)
            VStack {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(venue.gradient)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "soccerball")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                            )

                        Text(venue.city)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(16)
                    .padding(.leading, 10)
                    .padding(.top, 10)
                    .allowsHitTesting(false)

                    Spacer()

                    // Botones (esquina superior derecha)
                    VStack(spacing: 6) {
                        Button(action: onShowDetails) {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        }

                        Button(action: onClose) {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .padding(10)
                }
                Spacer()
            }
            .frame(height: 220)
        }
        .frame(height: 220)
        .padding(.horizontal, 16)
        .fullScreenCover(isPresented: $showFullScreen) {
            LookAroundView(coordinate: venue.coordinate, venueName: venue.name)
        }
    }
}


// Botón de categoría
struct CategoryButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color)
            )
            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

// Estados del modal deslizable
enum SheetState {
    case collapsed
    case partial
    case expanded

    func height(for geometry: GeometryProxy) -> CGFloat {
        switch self {
        case .collapsed: return 140
        case .partial: return 400
        case .expanded: return geometry.size.height - 100
        }
    }
}

// Modal deslizable tipo Google Maps
struct DraggableBottomSheet: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var selectedTab: Int
    let venues: [WorldCupVenue]
    let scheduledMatch: ScheduledMatch?
    @Binding var reservations: [VenueReservation]  // NUEVO: Recibir reservaciones

    @State private var currentHeight: CGFloat = 140
    @State private var sheetState: SheetState = .collapsed
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Indicador de arrastre
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 40, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    // Contenido según el estado
                    if sheetState == .collapsed {
                        CollapsedView(locationManager: locationManager, scheduledMatch: scheduledMatch)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    sheetState = .partial
                                    currentHeight = sheetState.height(for: geometry)
                                }
                            }
                    } else {
                        ExpandedView(
                            locationManager: locationManager,
                            venues: venues,
                            sheetState: $sheetState,
                            reservations: $reservations  // NUEVO: Pasar reservaciones
                        )
                    }

                    Spacer(minLength: 0)

                    // Tab Bar integrado
                    CustomTabBar(selectedTab: $selectedTab)
                        .padding(.bottom, 30)
                }
                .frame(height: max(140, currentHeight + dragOffset))
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .cornerRadius(30, corners: [.topLeft, .topRight])
                .clipped()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: -5)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation.height
                        }
                        .onEnded { value in
                            let snapDistance = value.translation.height
                            handleDragEnd(translation: snapDistance, geometry: geometry)
                        }
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentHeight)
                .onChange(of: sheetState) { oldState, newState in
                    currentHeight = newState.height(for: geometry)
                }
            }
        }
    }

    private func handleDragEnd(translation: CGFloat, geometry: GeometryProxy) {
        let velocityThreshold: CGFloat = 100

        // Deslizar hacia arriba (expandir) - translation negativo
        if translation < -velocityThreshold {
            if sheetState == .collapsed {
                sheetState = .partial
                currentHeight = sheetState.height(for: geometry)
            } else if sheetState == .partial {
                sheetState = .expanded
                currentHeight = sheetState.height(for: geometry)
            }
        }
        // Deslizar hacia abajo (colapsar) - translation positivo
        else if translation > velocityThreshold {
            if sheetState == .expanded {
                sheetState = .partial
                currentHeight = sheetState.height(for: geometry)
            } else if sheetState == .partial {
                sheetState = .collapsed
                currentHeight = sheetState.height(for: geometry)
            }
        }
        // Ajustar según posición actual
        else {
            snapToNearestState(geometry: geometry)
        }
    }

    private func snapToNearestState(geometry: GeometryProxy) {
        let collapsedHeight = SheetState.collapsed.height(for: geometry)
        let partialHeight = SheetState.partial.height(for: geometry)
        let expandedHeight = SheetState.expanded.height(for: geometry)

        let collapsedDistance = abs(currentHeight - collapsedHeight)
        let partialDistance = abs(currentHeight - partialHeight)
        let expandedDistance = abs(currentHeight - expandedHeight)

        let minDistance = min(collapsedDistance, partialDistance, expandedDistance)

        if minDistance == collapsedDistance {
            sheetState = .collapsed
            currentHeight = collapsedHeight
        } else if minDistance == partialDistance {
            sheetState = .partial
            currentHeight = partialHeight
        } else {
            sheetState = .expanded
            currentHeight = expandedHeight
        }
    }
}

// Vista colapsada (muestra partido agendado o ubicación)
struct CollapsedView: View {
    @ObservedObject var locationManager: LocationManager
    let scheduledMatch: ScheduledMatch?

    var body: some View {
        HStack(spacing: 12) {
            // Ícono según contenido
            Circle()
                .fill(scheduledMatch != nil ? Color.green : Color.blue)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: scheduledMatch != nil ? "sportscourt.fill" : "mappin.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                )

            // Información
            if let match = scheduledMatch {
                // Mostrar partido agendado
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(LocalizedString("map.matchScheduled"))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)

                        // Badge de estado
                        Text(match.status)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(statusColor(for: match.status))
                            .cornerRadius(8)
                    }

                    Text(match.venue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(shortDate(for: match.date))
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            } else {
                // Mostrar ubicación
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedString("map.yourLocation"))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    Text(locationName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Indicador de que se puede expandir
            Image(systemName: "chevron.up")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var locationName: String {
        if locationManager.checkAuthorization() {
            return "Ciudad de México"  // Aquí podrías usar geocoding real
        } else {
            return "Ubicación deshabilitada"
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "Confirmado": return .green
        case "Pendiente": return .orange
        case "Cancelado": return .red
        case "En espera": return .yellow
        default: return .blue
        }
    }

    private func shortDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, HH:mm"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}

// Vista expandida (con reservaciones)
struct ExpandedView: View {
    @ObservedObject var locationManager: LocationManager
    let venues: [WorldCupVenue]
    @Binding var sheetState: SheetState
    @Binding var reservations: [VenueReservation]  // NUEVO: Recibir reservaciones desde el parent

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedString("map.myReservations"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Text(String(format: LocalizedString("map.activeReservations"), reservations.count))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            sheetState = .collapsed
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Lista de reservaciones
                if reservations.isEmpty {
                    EmptyReservationsView()
                } else {
                    ForEach(reservations) { reservation in
                        ReservationCard(reservation: reservation)
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }
}

// Vista vacía de reservaciones
struct EmptyReservationsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(LocalizedString("map.noReservations"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text(LocalizedString("map.exploreVenues"))
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
}

// Status de reservación
enum ReservationStatus: String, Codable {
    case confirmed = "confirmed"
    case pending = "pending"
    case cancelled = "cancelled"

    var color: Color {
        switch self {
        case .confirmed: return .green
        case .pending: return .orange
        case .cancelled: return .red
        }
    }

    var text: String {
        switch self {
        case .confirmed: return "Confirmada"
        case .pending: return "Pendiente"
        case .cancelled: return "Cancelada"
        }
    }
}

// Modelo de reservación
struct VenueReservation: Identifiable, Codable {
    let id: UUID
    let venueName: String  // Cambiado de WorldCupVenue a String para ser Codable
    let venueCity: String
    let date: Date
    let seatNumber: String
    let status: String  // Cambiado de enum a String para ser Codable

    // Helper para crear desde WorldCupVenue
    init(id: UUID = UUID(), venue: WorldCupVenue, date: Date, seatNumber: String, status: ReservationStatus) {
        self.id = id
        self.venueName = venue.name
        self.venueCity = venue.city
        self.date = date
        self.seatNumber = seatNumber
        self.status = status.rawValue
    }

    // Init directo para Codable
    init(id: UUID = UUID(), venueName: String, venueCity: String, date: Date, seatNumber: String, status: String) {
        self.id = id
        self.venueName = venueName
        self.venueCity = venueCity
        self.date = date
        self.seatNumber = seatNumber
        self.status = status
    }

    var statusColor: Color {
        switch status {
        case "confirmed": return .green
        case "pending": return .orange
        case "cancelled": return .red
        default: return .blue
        }
    }

    var statusText: String {
        switch status {
        case "confirmed": return "Confirmada"
        case "pending": return "Pendiente"
        case "cancelled": return "Cancelada"
        default: return "Desconocido"
        }
    }
}

// Tarjeta de reservación
struct ReservationCard: View {
    let reservation: VenueReservation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Ícono de la sede con gradiente
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue,
                                Color.purple
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "soccerball")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(reservation.venueName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text(reservation.venueCity)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Spacer()

                // Estado
                Text(reservation.statusText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(reservation.statusColor)
                    )
            }

            Divider()
                .background(Color.gray.opacity(0.3))

            // Información del partido
            HStack(spacing: 20) {
                InfoItem(icon: "calendar", text: formattedDate)
                InfoItem(icon: "chair.fill", text: "Asiento \(reservation.seatNumber)")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal, 20)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: reservation.date)
    }
}

// Item de información
struct InfoItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white)
        }
    }
}

// Tab Bar personalizado integrado
struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            // Tab 1: Mapa
            TabBarItem(
                icon: "map.fill",
                title: LocalizedString("tab.map"),
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }

            // Tab 2: Comunidad
            TabBarItem(
                icon: "person.3.fill",
                title: LocalizedString("tab.community"),
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }

            // Tab 3: Álbum
            TabBarItem(
                icon: "square.grid.3x3.fill",
                title: LocalizedString("tab.album"),
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

// Item individual del Tab Bar
struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .blue : .gray)

                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// Tarjeta de permisos de ubicación
struct LocationPermissionCard: View {
    @ObservedObject var locationManager: LocationManager

    var body: some View {
        VStack(spacing: 16) {
            // Ícono
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 80, height: 80)

                Image(systemName: "location.slash.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            .padding(.top, 20)

            // Título
            Text("We can't log visits to\nyour Timeline")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Descripción
            Text("Location Services need to be enabled\nfor Superlocal to track where you go")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            // Botón
            Button(action: {
                locationManager.requestPermission()
            }) {
                Text("Enable Location")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.red)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.15))
        )
    }
}

// Extensión para Color darkGray
extension Color {
    static let darkGray = Color(white: 0.3)
}

// MARK: - Location Search Overlay
struct LocationSearchOverlay: View {
    @Binding var isPresented: Bool
    @ObservedObject var searchManager: LocationSearchManager
    let onLocationSelected: (CLLocationCoordinate2D, String) -> Void

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            // Fondo oscuro semi-transparente
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        isPresented = false
                        searchManager.clearSearch()
                    }
                }

            VStack(spacing: 0) {
                // Barra de búsqueda
                HStack(spacing: 12) {
                    // Botón volver
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            isPresented = false
                            searchManager.clearSearch()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                    }

                    // Campo de búsqueda
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))

                        TextField("Buscar lugares...", text: $searchManager.searchQuery)
                            .focused($isSearchFocused)
                            .font(.system(size: 16))
                            .foregroundColor(.black)

                        if !searchManager.searchQuery.isEmpty {
                            Button(action: {
                                searchManager.clearSearch()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(white: 0.95))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 60)
                .padding(.bottom, 12)
                .background(Color.white)

                // Resultados de búsqueda
                if searchManager.isSearching {
                    HStack {
                        ProgressView()
                            .padding()
                        Text("Buscando...")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    Spacer()
                } else if !searchManager.searchResults.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(searchManager.searchResults) { result in
                                SearchResultRow(result: result) {
                                    // Seleccionar este resultado
                                    handleResultSelection(result)
                                }
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .background(Color.white)
                } else if !searchManager.searchQuery.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No se encontraron resultados")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    Spacer()
                } else {
                    Spacer()
                        .background(Color.white)
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }

    private func handleResultSelection(_ result: SearchResult) {
        searchManager.selectResult(result) { coordinate, name in
            if let coord = coordinate {
                onLocationSelected(coord, name)
            }
        }
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: SearchResult
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icono basado en el tipo de lugar
                Image(systemName: result.placeType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 40)

                // Información del lugar
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .lineLimit(1)

                    if !result.subtitle.isEmpty {
                        Text(result.subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Icono de flecha
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Wrapper UIKit para Look Around - Interactivo inmediatamente
struct LookAroundUIKitWrapper: UIViewControllerRepresentable {
    let scene: MKLookAroundScene

    func makeUIViewController(context: Context) -> MKLookAroundViewController {
        let controller = MKLookAroundViewController()
        controller.scene = scene
        controller.isNavigationEnabled = true
        controller.showsRoadLabels = true

        // CRÍTICO: Asegurar interacción inmediata y completa
        controller.view.isUserInteractionEnabled = true
        controller.view.isMultipleTouchEnabled = true
        controller.view.isExclusiveTouch = true // Capturar todos los toques

        // Establecer prioridad alta de gestos
        if let panGesture = controller.view.gestureRecognizers?.first(where: { $0 is UIPanGestureRecognizer }) {
            panGesture.delaysTouchesBegan = false
            panGesture.cancelsTouchesInView = true
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: MKLookAroundViewController, context: Context) {
        // Actualizar la escena si cambia
        if uiViewController.scene != scene {
            uiViewController.scene = scene
        }

        // Reafirmar interactividad en cada actualización
        uiViewController.view.isUserInteractionEnabled = true
        uiViewController.view.isMultipleTouchEnabled = true
    }
}

// Vista bonita para compartir ubicación
struct ShareLocationSheet: View {
    let latitude: Double
    let longitude: Double
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Fondo oscuro semi-transparente
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        isPresented = false
                    }
                }

            VStack {
                Spacer()

                // Panel principal
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        // Indicador de arrastre
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 40, height: 5)
                            .padding(.top, 12)

                        // Título con ícono
                        HStack(spacing: 12) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Compartir Mi Ubicación")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)

                                Text("📍 \(String(format: "%.4f", latitude)), \(String(format: "%.4f", longitude))")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            // Botón cerrar
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    isPresented = false
                                }
                            }) {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: "xmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.7))
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 24)

                    // Opciones de compartir
                    VStack(spacing: 12) {
                        // Google Maps
                        ShareOptionButton(
                            icon: "map.fill",
                            title: "Abrir en Google Maps",
                            subtitle: "Ver en el navegador",
                            gradient: [Color(hex: "#4285F4"), Color(hex: "#34A853")]
                        ) {
                            if let url = URL(string: "https://maps.google.com/?q=\(latitude),\(longitude)") {
                                UIApplication.shared.open(url)
                            }
                        }

                        // Apple Maps
                        ShareOptionButton(
                            icon: "map.fill",
                            title: "Abrir en Apple Maps",
                            subtitle: "Navegar con Maps",
                            gradient: [Color(hex: "#007AFF"), Color(hex: "#5AC8FA")]
                        ) {
                            if let url = URL(string: "http://maps.apple.com/?ll=\(latitude),\(longitude)") {
                                UIApplication.shared.open(url)
                            }
                        }

                        // Copiar coordenadas
                        ShareOptionButton(
                            icon: "doc.on.doc.fill",
                            title: "Copiar Coordenadas",
                            subtitle: "Lat: \(String(format: "%.6f", latitude)), Lon: \(String(format: "%.6f", longitude))",
                            gradient: [Color.purple, Color.pink]
                        ) {
                            UIPasteboard.general.string = "\(latitude), \(longitude)"
                            // Feedback háptico
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)

                            // Cerrar después de copiar
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    isPresented = false
                                }
                            }
                        }

                        // Compartir con otras apps
                        ShareOptionButton(
                            icon: "square.and.arrow.up.fill",
                            title: "Compartir con...",
                            subtitle: "WhatsApp, Messages, Mail, etc.",
                            gradient: [Color(hex: "#00A651"), Color(hex: "#00E676")]
                        ) {
                            // Compartir con UIActivityViewController
                            let locationText = """
                            Mi ubicación actual:
                            📍 Lat: \(String(format: "%.6f", latitude)), Lon: \(String(format: "%.6f", longitude))

                            Google Maps: https://maps.google.com/?q=\(latitude),\(longitude)
                            Apple Maps: http://maps.apple.com/?ll=\(latitude),\(longitude)
                            """

                            let activityVC = UIActivityViewController(
                                activityItems: [locationText],
                                applicationActivities: nil
                            )

                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootViewController = windowScene.windows.first?.rootViewController {
                                var topController = rootViewController
                                while let presented = topController.presentedViewController {
                                    topController = presented
                                }

                                // Para iPad
                                if let popover = activityVC.popoverPresentationController {
                                    popover.sourceView = topController.view
                                    popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
                                    popover.permittedArrowDirections = []
                                }

                                topController.present(activityVC, animated: true)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color(white: 0.1))
                        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: -5)
                )
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// Botón de opción para compartir
struct ShareOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Ícono con gradiente
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    )
                    .shadow(color: gradient[0].opacity(0.4), radius: 8, x: 0, y: 4)

                // Textos
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }

                Spacer()

                // Flecha
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    WorldCupMapView(
        selectedTab: .constant(0),
        collectionManager: StickerCollectionManager(),
        lastCollectedVenue: .constant(nil),
        showCollectionAnimation: .constant(false)
    )
}
