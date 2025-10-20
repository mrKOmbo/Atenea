//
//  HamburgerMenuView.swift
//  Atenea
//
//  Created by Claude on 10/12/25.
//

import SwiftUI
import AVFoundation

struct HamburgerMenuView: View {
    @Binding var isMenuOpen: Bool
    @Binding var showARView: Bool

    var body: some View {
        ZStack(alignment: .trailing) {
            // Overlay oscuro al fondo cuando el menú está abierto
            if isMenuOpen {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isMenuOpen = false
                        }
                    }
                    .transition(.opacity)
            }

            // Panel del menú que se desliza desde la derecha
            if isMenuOpen {
                MenuPanel(isMenuOpen: $isMenuOpen, showARView: $showARView)
                    .transition(.move(edge: .trailing))
            }
        }
    }
}

// Panel del menú lateral con efecto liquid glass
struct MenuPanel: View {
    @Binding var isMenuOpen: Bool
    @Binding var showARView: Bool
    @State private var showPermissionAlert = false
    @State private var showPlayerScanner = false  // 🎯 Scanner de jugadores AR
    @StateObject private var cameraPermissionManager = CameraPermissionManager()
    @EnvironmentObject var languageManager: LanguageManager
    @State private var isLanguageExpanded = false

    // Idiomas disponibles con sus nombres nativos
    let availableLanguages: [(code: String, name: String)] = [
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

    // Nombre del idioma actual
    var currentLanguageName: String {
        availableLanguages.first(where: { $0.code == languageManager.currentLanguage })?.name ?? "English"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header del menú con gradiente
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedString("menu.worldCup2026"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(LocalizedString("menu.mainMenu"))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isMenuOpen = false
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.08)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Contenido del menú con secciones
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Sección: Navegación
                    MenuSection(title: LocalizedString("menu.navigation")) {
                        MenuItemView(
                            icon: "map.fill",
                            title: LocalizedString("menu.venueMap"),
                            color: .cyan
                        ) {
                            print("Mapa de Sedes seleccionado")
                            withAnimation {
                                isMenuOpen = false
                            }
                        }

                        MenuItemView(
                            icon: "location.fill",
                            title: LocalizedString("menu.myLocation"),
                            color: .blue
                        ) {
                            print("Mi Ubicación seleccionado")
                            withAnimation {
                                isMenuOpen = false
                            }
                        }
                    }

                    // Sección: Mundial
                    MenuSection(title: LocalizedString("menu.worldCupSection")) {
                        MenuItemView(
                            icon: "calendar",
                            title: LocalizedString("menu.calendar"),
                            color: .orange
                        ) {
                            print("Calendario seleccionado")
                            withAnimation {
                                isMenuOpen = false
                            }
                        }

                        MenuItemView(
                            icon: "sportscourt.fill",
                            title: LocalizedString("menu.matches"),
                            color: .red
                        ) {
                            print("Partidos seleccionado")
                            withAnimation {
                                isMenuOpen = false
                            }
                        }

                        MenuItemView(
                            icon: "star.fill",
                            title: LocalizedString("menu.favorites"),
                            color: .yellow
                        ) {
                            print("Favoritos seleccionado")
                            withAnimation {
                                isMenuOpen = false
                            }
                        }
                    }

                    // Sección: Transporte
                    MenuSection(title: LocalizedString("menu.transportSection")) {
                        MenuItemView(
                            icon: "car.fill",
                            title: LocalizedString("menu.transportModes"),
                            color: .green
                        ) {
                            print("Transportes seleccionado")
                            withAnimation {
                                isMenuOpen = false
                            }
                        }

                        MenuItemView(
                            icon: "map.circle.fill",
                            title: LocalizedString("menu.routes"),
                            color: .teal
                        ) {
                            print("Rutas seleccionado")
                            withAnimation {
                                isMenuOpen = false
                            }
                        }
                    }

                    // Sección: Otros
                    MenuSection(title: LocalizedString("menu.othersSection")) {
                        MenuItemView(
                            icon: "camera.viewfinder",
                            title: LocalizedString("menu.ar"),
                            color: .pink
                        ) {
                            print("🎯 Realidad Aumentada seleccionado")
                            withAnimation {
                                isMenuOpen = false
                            }
                            // Verificar permisos de cámara con delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                checkCameraPermissionAndShowAR()
                            }
                        }

                        // 🎯 NUEVO: Scanner AR de Jugadores
                        MenuItemView(
                            icon: "person.crop.rectangle.stack",
                            title: LocalizedString("menu.scanPlayers"),
                            color: Color(red: 0.0, green: 0.7, blue: 0.4)
                        ) {
                            print("🎯 Scanner de Jugadores seleccionado")
                            withAnimation {
                                isMenuOpen = false
                            }
                            // Abrir scanner con delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showPlayerScanner = true
                            }
                        }

                        MenuItemView(
                            icon: "info.circle.fill",
                            title: LocalizedString("menu.information"),
                            color: .purple
                        ) {
                            print("Información seleccionado")
                            withAnimation {
                                isMenuOpen = false
                            }
                        }

                        MenuItemView(
                            icon: "gearshape.fill",
                            title: LocalizedString("menu.settings"),
                            color: .gray
                        ) {
                            print("Configuración seleccionado")
                            withAnimation {
                                isMenuOpen = false
                            }
                        }
                    }

                    // Sección: Idioma
                    MenuSection(title: LocalizedString("profile.language").uppercased()) {
                        VStack(spacing: 0) {
                            // Botón principal para mostrar idioma actual
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isLanguageExpanded.toggle()
                                }
                            }) {
                                HStack(spacing: 14) {
                                    // Ícono
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.indigo,
                                                        Color.indigo.opacity(0.85)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 44, height: 44)
                                            .shadow(color: Color.indigo.opacity(0.5), radius: 8, x: 0, y: 4)
                                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)

                                        Image(systemName: "globe")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                    }

                                    // Idioma actual
                                    Text(currentLanguageName)
                                        .font(.system(size: 15))
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)

                                    Spacer()

                                    // Chevron
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white.opacity(0.4))
                                        .rotationEffect(.degrees(isLanguageExpanded ? 90 : 0))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Opciones de idioma desplegadas
                            if isLanguageExpanded {
                                VStack(spacing: 4) {
                                    ForEach(availableLanguages, id: \.code) { language in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                languageManager.setLanguage(language.code)
                                                isLanguageExpanded = false
                                            }
                                        }) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(languageManager.currentLanguage == language.code ? .green : .clear)
                                                    .frame(width: 20)

                                                Text(language.name)
                                                    .font(.system(size: 14, weight: languageManager.currentLanguage == language.code ? .semibold : .regular))
                                                    .foregroundColor(.white)

                                                Spacer()
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(languageManager.currentLanguage == language.code ? Color.green.opacity(0.15) : Color.white.opacity(0.05))
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal, 4)
                                    }
                                }
                                .padding(.top, 8)
                                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                            }
                        }
                    }
                }
                .padding(.vertical, 20)
                .padding(.bottom, 20)
            }

            // Footer del menú con diseño mejorado
            VStack(spacing: 12) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "soccerball.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedString("menu.fifaWorldCup"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.9))
                            Text(LocalizedString("menu.version"))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.05),
                        Color.white.opacity(0.08)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(width: 320)
        .frame(maxHeight: .infinity)
        .background(
            // Efecto Liquid Glass más transparente
            ZStack {
                // Material de vidrio con blur
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .opacity(0.6)

                // Gradiente de fondo semi-transparente (más ligero)
                RoundedRectangle(cornerRadius: 24)
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

                // Brillo sutil en la parte superior
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.08),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            // Borde brillante con gradiente
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 40, x: -15, y: 0)
        .shadow(color: .black.opacity(0.2), radius: 15, x: -5, y: 0)
        .padding(.vertical, 40)
        .padding(.trailing, 16)
        .alert(LocalizedString("menu.cameraPermission"), isPresented: $showPermissionAlert) {
            Button(LocalizedString("action.openSettings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(LocalizedString("action.cancel"), role: .cancel) { }
        } message: {
            Text(LocalizedString("menu.cameraAccess"))
        }
        // 🎯 Scanner AR de Jugadores
        .fullScreenCover(isPresented: $showPlayerScanner) {
            ARPlayerScannerView(isPresented: $showPlayerScanner)
        }
    }

    // MARK: - Helper Methods

    private func checkCameraPermissionAndShowAR() {
        print("🔍 Checking camera permissions...")
        let status = cameraPermissionManager.checkPermission()
        print("📸 Camera permission status: \(status.rawValue)")

        switch status {
        case .authorized:
            // Ya tenemos permisos, ir directo a AR
            print("✅ Camera authorized, opening AR view directly")
            showARView = true
        case .notDetermined:
            // Solicitar permisos
            print("❓ Requesting camera permission...")
            cameraPermissionManager.requestPermission()
            // Esperar respuesta
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("🔄 Checking permission result: \(self.cameraPermissionManager.permissionGranted)")
                if self.cameraPermissionManager.permissionGranted {
                    print("✅ Permission granted, opening AR view")
                    self.showARView = true
                } else {
                    print("❌ Permission was denied by user")
                    self.showPermissionAlert = true
                }
            }
        case .denied, .restricted:
            // Mostrar alerta indicando que deben habilitar permisos en configuración
            print("⚠️ Permisos de cámara denegados. Mostrando alerta.")
            showPermissionAlert = true
        @unknown default:
            print("⚠️ Unknown permission status")
            break
        }
    }
}

// Componente para agrupar secciones del menú
struct MenuSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Título de la sección
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 20)
                .padding(.top, 4)

            // Contenido de la sección
            VStack(spacing: 4) {
                content
            }
        }
    }
}

// Vista para cada item del menú con efecto glass mejorado
struct MenuItemView: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Ícono con fondo sólido y vibrante
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color,
                                    color.opacity(0.85)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: color.opacity(0.5), radius: 8, x: 0, y: 4)
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }

                // Título
                Text(title)
                    .font(.system(size: 15))
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isPressed {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.15),
                                            Color.white.opacity(0.08)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            RoundedRectangle(cornerRadius: 12)
                                .fill(color.opacity(0.08))
                        }
                        .padding(.horizontal, 4)
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPressed = false
                    }
                }
        )
    }
}

// Botón de hamburguesa con efecto liquid glass
struct HamburgerButton: View {
    @Binding var isMenuOpen: Bool

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isMenuOpen.toggle()
            }
        }) {
            ZStack {
                // Fondo con efecto glass
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 50, height: 50)
                    )

                // Ícono de hamburguesa animado
                VStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.9)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 22, height: 2.5)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .rotationEffect(.degrees(isMenuOpen ? 45 : 0))
                        .offset(y: isMenuOpen ? 7.5 : 0)

                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.9)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 22, height: 2.5)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .opacity(isMenuOpen ? 0 : 1)
                        .scaleEffect(isMenuOpen ? 0.5 : 1)

                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.9)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 22, height: 2.5)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .rotationEffect(.degrees(isMenuOpen ? -45 : 0))
                        .offset(y: isMenuOpen ? -7.5 : 0)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        // Simular un mapa de fondo más realista
        Image(systemName: "map.fill")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .foregroundColor(.blue.opacity(0.2))
            .ignoresSafeArea()

        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.4),
                Color.green.opacity(0.3),
                Color.teal.opacity(0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        // Elementos decorativos
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(LocalizedString("menu.worldCup2026"))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(LocalizedString("menu.countries"))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                Spacer()
            }
            Spacer()
        }

        // Menú hamburguesa
        HamburgerMenuView(isMenuOpen: .constant(true), showARView: .constant(false))
    }
}
