//
//  ProfileMenuView.swift
//  Atenea
//
//  Created by Claude on 10/13/25.
//

import SwiftUI
import MapKit

// Modelo de datos para partido agendado
struct ScheduledMatch: Identifiable {
    let id = UUID()
    var venue: String
    var seats: String
    var date: Date
    var status: String

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}

// Tipos de mapa disponibles
enum MapMode: String, CaseIterable {
    case explore = "Explore"
    case driving = "Driving"
    case transit = "Transit"
    case satellite = "Satellite"

    var icon: String {
        switch self {
        case .explore: return "map.fill"
        case .driving: return "car.fill"
        case .transit: return "tram.fill"
        case .satellite: return "globe.americas.fill"
        }
    }

    var mkMapType: MKMapType {
        switch self {
        case .explore: return .standard
        case .driving: return .mutedStandard
        case .transit: return .standard
        case .satellite: return .satellite
        }
    }
}

// Menú de perfil de usuario tipo Fog of World
struct ProfileMenuPanel: View {
    @Binding var isMenuOpen: Bool
    @Binding var selectedMapMode: MapMode
    @Binding var scheduledMatch: ScheduledMatch?
    @Binding var showVenuesView: Bool
    @State private var isMapModeExpanded = false
    @State private var isLanguageExpanded = false
    @State private var showAPIKeySetup = false
    @EnvironmentObject var languageManager: LanguageManager

    // Mapeo de códigos de idioma a nombres nativos
    let languageMap: [(code: String, name: String)] = [
        ("es", "Español"),
        ("en", "English"),
        ("pt", "Português"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("it", "Italiano"),
        ("nl", "Nederlands"),
        ("ja", "日本語"),
        ("ko", "한국어")
    ]

    var currentLanguageName: String {
        languageMap.first(where: { $0.code == languageManager.currentLanguage })?.name ?? "English"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header minimalista
            HStack {
                Text(LocalizedString("profile.menu"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                // Botón de cerrar
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isMenuOpen = false
                    }
                }) {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 24)

            // Contenido scrollable
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Perfil de usuario
                    UserProfileSection()

                    // Desplegable de tipo de mapa
                    DropdownSection(
                        title: LocalizedString("profile.mapType"),
                        selectedOption: selectedMapMode.rawValue,
                        icon: selectedMapMode.icon,
                        isExpanded: $isMapModeExpanded
                    ) {
                        ForEach(MapMode.allCases, id: \.self) { mode in
                            DropdownOption(
                                title: mode.rawValue,
                                icon: mode.icon,
                                isSelected: selectedMapMode == mode
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedMapMode = mode
                                    isMapModeExpanded = false
                                }
                            }
                        }
                    }

                    // Desplegable de idioma
                    DropdownSection(
                        title: LocalizedString("profile.language"),
                        selectedOption: currentLanguageName,
                        icon: "globe",
                        isExpanded: $isLanguageExpanded
                    ) {
                        ForEach(languageMap, id: \.code) { language in
                            DropdownOption(
                                title: language.name,
                                icon: "flag.fill",
                                isSelected: languageManager.currentLanguage == language.code
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    languageManager.setLanguage(language.code)
                                    isLanguageExpanded = false
                                }
                            }
                        }
                    }

                    // Botón de configurar API de Claude
                    Button(action: {
                        showAPIKeySetup = true
                        isMenuOpen = false
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedString("profile.claudeAPI"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)

                                Text(APIConfiguration.shared.hasClaudeAPIKey ? LocalizedString("profile.configured") : LocalizedString("profile.notConfigured"))
                                    .font(.system(size: 12))
                                    .foregroundColor(APIConfiguration.shared.hasClaudeAPIKey ? .green : .orange)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.cyan.opacity(0.6),
                                    Color.blue.opacity(0.5)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 20)

                    // Botón de agendar partido
                    Button(action: {
                        showVenuesView = true
                        isMenuOpen = false
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32)

                            Text(LocalizedString("profile.scheduleMatch"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.6),
                                    Color.purple.opacity(0.5)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }

            Spacer()
        }
        .frame(width: 320)
        .frame(maxHeight: .infinity)
        .background(
            ZStack {
                // Material de vidrio con blur
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.6)

                // Gradiente de fondo semi-transparente
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.04),
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.06)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            // Borde brillante sutil en el lado izquierdo
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 1)
                .frame(maxHeight: .infinity)
                .frame(maxWidth: .infinity, alignment: .leading)
        )
        .shadow(color: .black.opacity(0.5), radius: 40, x: -15, y: 0)
        .ignoresSafeArea()
        .sheet(isPresented: $showAPIKeySetup) {
            APIKeySetupView()
        }
    }
}

// Lista de idiomas disponibles
let availableLanguages = [
    "Español",
    "English",
    "Français",
    "Deutsch",
    "Italiano",
    "Português",
    "中文",
    "日本語",
    "한국어",
    "العربية",
    "Русский",
    "Nederlands",
    "Polski",
    "Türkçe",
    "Svenska",
    "Norsk",
    "Dansk",
    "Suomi"
]

// Sección del perfil de usuario
struct UserProfileSection: View {
    var body: some View {
        HStack(spacing: 16) {
            // Avatar con iniciales
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Text("EC")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                )

            // Información del usuario
            VStack(alignment: .leading, spacing: 4) {
                Text("Emi Cruz")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Text("Mundial 2026")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(white: 0.1))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}

// Componente de sección desplegable
struct DropdownSection<Content: View>: View {
    let title: String
    let selectedOption: String
    let icon: String
    @Binding var isExpanded: Bool
    let content: Content

    init(title: String, selectedOption: String, icon: String, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.title = title
        self.selectedOption = selectedOption
        self.icon = icon
        self._isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Botón principal del desplegable
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Ícono
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32)

                    // Textos
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        Text(selectedOption)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Chevron indicador
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())

            // Opciones desplegadas
            if isExpanded {
                VStack(spacing: 4) {
                    content
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 20)
    }
}

// Componente de opción dentro del desplegable
struct DropdownOption: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Ícono
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.6))
                    .frame(width: 24)

                // Título
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .blue : .white)

                Spacer()

                // Check mark si está seleccionado
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.15) : Color.white.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Vista de selección de sedes
struct VenuesSelectionView: View {
    @Binding var isPresented: Bool
    let onVenueSelected: (String) -> Void

    let venues = [
        VenueInfo(
            name: "Estadio Azteca",
            location: "Ciudad de México, México",
            capacity: "87,523",
            fullName: "Estadio Azteca - México",
            image: "photo.on.rectangle.angled"
        ),
        VenueInfo(
            name: "Estadio BBVA",
            location: "Monterrey, México",
            capacity: "53,500",
            fullName: "Estadio BBVA - Monterrey",
            image: "photo.on.rectangle.angled"
        ),
        VenueInfo(
            name: "Estadio Akron",
            location: "Guadalajara, México",
            capacity: "49,850",
            fullName: "Estadio Akron - Guadalajara",
            image: "photo.on.rectangle.angled"
        ),
        VenueInfo(
            name: "SoFi Stadium",
            location: "Los Ángeles, USA",
            capacity: "70,240",
            fullName: "SoFi Stadium - Los Ángeles",
            image: "photo.on.rectangle.angled"
        ),
        VenueInfo(
            name: "MetLife Stadium",
            location: "Nueva York/Nueva Jersey, USA",
            capacity: "82,500",
            fullName: "MetLife Stadium - Nueva York",
            image: "photo.on.rectangle.angled"
        ),
        VenueInfo(
            name: "AT&T Stadium",
            location: "Dallas, USA",
            capacity: "80,000",
            fullName: "AT&T Stadium - Dallas",
            image: "photo.on.rectangle.angled"
        ),
        VenueInfo(
            name: "Arrowhead Stadium",
            location: "Kansas City, USA",
            capacity: "76,416",
            fullName: "Arrowhead Stadium - Kansas City",
            image: "photo.on.rectangle.angled"
        ),
        VenueInfo(
            name: "Mercedes-Benz Stadium",
            location: "Atlanta, USA",
            capacity: "71,000",
            fullName: "Mercedes-Benz Stadium - Atlanta",
            image: "photo.on.rectangle.angled"
        ),
        VenueInfo(
            name: "Lumen Field",
            location: "Seattle, USA",
            capacity: "68,740",
            fullName: "Lumen Field - Seattle",
            image: "photo.on.rectangle.angled"
        ),
        VenueInfo(
            name: "Levi's Stadium",
            location: "San Francisco, USA",
            capacity: "68,500",
            fullName: "Levi's Stadium - San Francisco",
            image: "photo.on.rectangle.angled"
        ),
        VenueInfo(
            name: "BMO Field",
            location: "Toronto, Canadá",
            capacity: "45,736",
            fullName: "BMO Field - Toronto",
            image: "photo.on.rectangle.angled"
        ),
        VenueInfo(
            name: "BC Place",
            location: "Vancouver, Canadá",
            capacity: "54,500",
            fullName: "BC Place - Vancouver",
            image: "photo.on.rectangle.angled"
        )
    ]

    var body: some View {
        ZStack {
            // Fondo con gradiente
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.05, green: 0.05, blue: 0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header con botón de cerrar
                HStack {
                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 40, height: 40)

                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 10)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)

                            Text(LocalizedString("profile.selectVenue"))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text(LocalizedString("profile.selectVenueDesc"))
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 10)

                        // Lista de sedes
                        VStack(spacing: 12) {
                            ForEach(venues) { venue in
                                VenueCard(venue: venue) {
                                    onVenueSelected(venue.fullName)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Capturar toques en el área vacía
        }
    }
}

// Modelo para información de sede
struct VenueInfo: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let capacity: String
    let fullName: String
    let image: String
}

// Tarjeta de sede
struct VenueCard: View {
    let venue: VenueInfo
    let action: () -> Void

    @State private var isPressed = false
    @State private var isHovered = false

    var body: some View {
        Button(action: {
            // Feedback háptico
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                action()
            }
        }) {
            HStack(spacing: 16) {
                // Ícono de estadio
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    isPressed ? Color.blue.opacity(0.6) : Color.blue.opacity(0.3),
                                    isPressed ? Color.purple.opacity(0.6) : Color.purple.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: isPressed ? Color.blue.opacity(0.5) : Color.clear, radius: 10, x: 0, y: 5)

                    Image(systemName: "building.2.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                }

                // Información
                VStack(alignment: .leading, spacing: 6) {
                    Text(venue.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(isPressed ? .cyan : .blue)

                        Text(venue.location)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 12))
                            .foregroundColor(isPressed ? .mint : .green)

                        Text("\(LocalizedString("profile.capacity")): \(venue.capacity)")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // Chevron animado
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isPressed ? .white.opacity(0.8) : .white.opacity(0.3))
                    .offset(x: isPressed ? 5 : 0)
            }
            .padding(16)
            .background(
                ZStack {
                    // Fondo base
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isPressed ? Color.white.opacity(0.15) : Color.white.opacity(0.08))

                    // Glow effect cuando se presiona
                    if isPressed {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.2),
                                        Color.purple.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isPressed ?
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                        lineWidth: isPressed ? 2 : 1
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .shadow(color: isPressed ? Color.blue.opacity(0.3) : Color.black.opacity(0.1), radius: isPressed ? 15 : 5, x: 0, y: isPressed ? 8 : 3)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPressed = false
                    }
                }
        )
    }
}

// Modal para agendar partido
struct ScheduleMatchModal: View {
    @Binding var isPresented: Bool
    @Binding var scheduledMatch: ScheduledMatch?
    let preselectedVenue: String?
    var onMatchScheduled: (() -> Void)? = nil  // NUEVO: Callback al confirmar reserva
    @State private var selectedVenue = "Estadio Azteca - México"
    @State private var selectedSeats = ""
    @State private var selectedDate = Date()
    @State private var selectedStatus = "Confirmado"
    @State private var isVenueExpanded = false
    @State private var isStatusExpanded = false
    @State private var showSuccessAlert = false

    let venues = [
        "Estadio Azteca - México",
        "Estadio BBVA - Monterrey",
        "Estadio Akron - Guadalajara",
        "SoFi Stadium - Los Ángeles",
        "MetLife Stadium - Nueva York",
        "AT&T Stadium - Dallas",
        "Arrowhead Stadium - Kansas City",
        "Mercedes-Benz Stadium - Atlanta",
        "Lumen Field - Seattle",
        "Levi's Stadium - San Francisco",
        "BMO Field - Toronto",
        "BC Place - Vancouver"
    ]

    var statusOptions: [String] {
        [
            LocalizedString("status.confirmed"),
            LocalizedString("status.pending"),
            LocalizedString("status.cancelled"),
            LocalizedString("status.waiting")
        ]
    }

    var body: some View {
        ZStack {
            // Fondo con gradiente
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.05, green: 0.05, blue: 0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header con botón de cerrar
                HStack {
                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 40, height: 40)

                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 10)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header con título
                        VStack(spacing: 8) {
                            Image(systemName: "sportscourt.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)

                            Text(LocalizedString("profile.scheduleMatch"))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text(LocalizedString("profile.completeData"))
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 10)

                        // Formulario
                        VStack(spacing: 20) {
                            // Selector de Estadio
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("profile.venue"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))

                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isVenueExpanded.toggle()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "building.2.fill")
                                            .foregroundColor(.blue)

                                        Text(selectedVenue)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)

                                        Spacer()

                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.5))
                                            .rotationEffect(.degrees(isVenueExpanded ? 180 : 0))
                                    }
                                    .padding(16)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())

                                if isVenueExpanded {
                                    VStack(spacing: 4) {
                                        ForEach(venues, id: \.self) { venue in
                                            Button(action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedVenue = venue
                                                    isVenueExpanded = false
                                                }
                                            }) {
                                                HStack {
                                                    Text(venue)
                                                        .font(.system(size: 15))
                                                        .foregroundColor(selectedVenue == venue ? .blue : .white)

                                                    Spacer()

                                                    if selectedVenue == venue {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 14, weight: .bold))
                                                            .foregroundColor(.blue)
                                                    }
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(selectedVenue == venue ? Color.blue.opacity(0.15) : Color.white.opacity(0.05))
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }

                            // Campo de Asientos
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("profile.seats"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))

                                HStack {
                                    Image(systemName: "chair.fill")
                                        .foregroundColor(.blue)

                                    TextField(LocalizedString("profile.seatsPlaceholder"), text: $selectedSeats)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .tint(.blue)
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }

                            // Selector de Fecha
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("profile.dateTime"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))

                                DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .tint(.blue)
                                    .padding(16)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                            }

                            // Selector de Estado
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("profile.status"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))

                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isStatusExpanded.toggle()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: statusIcon(for: selectedStatus))
                                            .foregroundColor(statusColor(for: selectedStatus))

                                        Text(selectedStatus)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)

                                        Spacer()

                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.5))
                                            .rotationEffect(.degrees(isStatusExpanded ? 180 : 0))
                                    }
                                    .padding(16)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())

                                if isStatusExpanded {
                                    VStack(spacing: 4) {
                                        ForEach(statusOptions, id: \.self) { status in
                                            Button(action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedStatus = status
                                                    isStatusExpanded = false
                                                }
                                            }) {
                                                HStack {
                                                    Image(systemName: statusIcon(for: status))
                                                        .foregroundColor(statusColor(for: status))

                                                    Text(status)
                                                        .font(.system(size: 15))
                                                        .foregroundColor(selectedStatus == status ? statusColor(for: status) : .white)

                                                    Spacer()

                                                    if selectedStatus == status {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 14, weight: .bold))
                                                            .foregroundColor(statusColor(for: status))
                                                    }
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(selectedStatus == status ? statusColor(for: status).opacity(0.15) : Color.white.opacity(0.05))
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Botón de confirmar
                        Button(action: {
                            // Guardar el partido agendado
                            scheduledMatch = ScheduledMatch(
                                venue: selectedVenue,
                                seats: selectedSeats.isEmpty ? "Por asignar" : selectedSeats,
                                date: selectedDate,
                                status: selectedStatus
                            )
                            showSuccessAlert = true
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))

                                Text(LocalizedString("profile.confirmReservation"))
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Capturar toques en el área vacía
        }
        .alert(LocalizedString("profile.reservationConfirmed"), isPresented: $showSuccessAlert) {
            Button(LocalizedString("action.accept")) {
                isPresented = false
                // Llamar al callback para cerrar el menú y mostrar el partido agendado
                onMatchScheduled?()
            }
        } message: {
            Text("\(LocalizedString("profile.yourMatchAt")) \(selectedVenue) ha sido agendado exitosamente para el \(formattedDate)")
        }
        .onAppear {
            if let venue = preselectedVenue {
                selectedVenue = venue
            }
        }
    }

    // Helper functions
    private func statusIcon(for status: String) -> String {
        switch status {
        case LocalizedString("status.confirmed"): return "checkmark.circle.fill"
        case LocalizedString("status.pending"): return "clock.fill"
        case LocalizedString("status.cancelled"): return "xmark.circle.fill"
        case LocalizedString("status.waiting"): return "hourglass"
        default: return "circle.fill"
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case LocalizedString("status.confirmed"): return .green
        case LocalizedString("status.pending"): return .orange
        case LocalizedString("status.cancelled"): return .red
        case LocalizedString("status.waiting"): return .yellow
        default: return .blue
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: selectedDate)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ProfileMenuPanel(isMenuOpen: .constant(true), selectedMapMode: .constant(.explore), scheduledMatch: .constant(nil), showVenuesView: .constant(false))
    }
}
