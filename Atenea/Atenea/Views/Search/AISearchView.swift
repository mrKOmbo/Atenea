//
//  AISearchView.swift
//  Atenea
//
//  Created by Claude on 10/13/25.
//

import SwiftUI
import MapKit

struct AISearchView: View {
    @Binding var isPresented: Bool
    var selectedCategory: String?
    var onNavigateToLocation: (CLLocationCoordinate2D, String, Double) -> Void
    var onShowDirections: (CLLocationCoordinate2D, String) -> Void  // NUEVO: Callback para mostrar direcciones

    @State private var messageText: String = ""
    @FocusState private var isMessageFocused: Bool
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging = false
    @State private var sheetState: SheetState = .full  // Cambiado a .full para pantalla casi completa
    @State private var showContent: Bool = false
    @State private var showHistoryModal: Bool = false  // Control del modal de historial
    @State private var showMemorySettings: Bool = false  // Control del modal de Memory
    @State private var showAPIKeySettings: Bool = false  // Control del modal de configuración de API
    @State private var keyboardHeight: CGFloat = 0  // Altura del teclado

    // NUEVO: Chat con Claude
    @State private var chatMessages: [ChatMessage] = [
        ChatMessage(text: "¡Hola! 👋 Soy Claude, tu asistente de IA. ¿Qué te gustaría descubrir hoy?", isUser: false)
    ]
    @StateObject private var claudeService = ClaudeAPIService(apiKey: APIConfiguration.shared.claudeAPIKey)
    @State private var showAPIKeyAlert: Bool = false

    enum SheetState {
        case medium     // 65% de pantalla (por defecto)
        case full       // Pantalla completa

        func height(for screenHeight: CGFloat) -> CGFloat {
            switch self {
            case .medium: return min(screenHeight * 0.65, 600)
            case .full: return screenHeight - 50
            }
        }
    }

    var body: some View {
        baseContentView
            .overlay(modalsOverlay)
            .alert("Claude API Key Required", isPresented: $showAPIKeyAlert) {
                Button("Configure API Key", role: .none) {
                    showAPIKeySettings = true
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please configure your Claude API key to use AI chat features. Tap 'Configure API Key' to set it up now.")
            }
            .onAppear(perform: handleAppear)
            .onDisappear(perform: handleDisappear)
    }

    private var baseContentView: some View {
        ZStack {
            // Overlay de fondo para cubrir todo
            Color.black.opacity(0.001)
                .ignoresSafeArea()

            mainContentView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    @ViewBuilder
    private var modalsOverlay: some View {
        // Modal de historial
        if showHistoryModal {
            HistoryView(isPresented: $showHistoryModal)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1000)
        }

        // Modal de Memory Settings
        if showMemorySettings {
            MemorySettingsView(isPresented: $showMemorySettings)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1001)
        }

        // Modal de API Key Settings
        if showAPIKeySettings {
            APIKeySettingsView(isPresented: $showAPIKeySettings)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1002)
        }
    }

    private func handleAppear() {
        // Animación de entrada escalonada para contenido
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.35)) {
                showContent = true
            }
        }

        // Auto-enfocar el campo de mensajes para levantar el teclado
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isMessageFocused = true
        }

        // Observers para el teclado
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
    }

    private func handleDisappear() {
        showContent = false
        isMessageFocused = false  // Quitar focus del teclado al cerrar

        // Remover observers del teclado
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - Subviews

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.white.opacity(0.3))
            .frame(width: 40, height: 5)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.2).delay(0.1), value: showContent)
    }

    private var backgroundOverlayView: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isPresented = false
                }
            }
    }

    private var mainContentView: some View {
        VStack(spacing: 0) {
            headerView

            headerButtons
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.3).delay(0.15), value: showContent)

            chatMessagesArea
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)

            Spacer(minLength: 100)

            chatInputBar
                .padding(.horizontal, 16)
                .padding(.bottom, max(keyboardHeight, 34))
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black)
        .ignoresSafeArea()
    }

    private var headerView: some View {
        HStack {
            Text("AI Search")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isPresented = false
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
        .padding(.top, 55)
        .padding(.bottom, 12)
    }

    private var headerButtons: some View {
        HStack(spacing: 8) {
            historyButton
            Spacer()
            apiSettingsButton
            memoryButton
        }
    }

    private var historyButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showHistoryModal = true
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 13, weight: .semibold))
                Text("History")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .buttonStyle(HistoryButtonStyle(isActive: showHistoryModal))
    }

    private var apiSettingsButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showAPIKeySettings = true
            }
        }) {
            Image(systemName: APIConfiguration.shared.hasClaudeAPIKey ? "key.fill" : "key")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(APIConfiguration.shared.hasClaudeAPIKey ? Color(hex: "#00D084") : .white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color(white: 0.15))
                )
        }
    }

    private var memoryButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showMemorySettings = true
            }
        }) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 40, height: 40)
        }
        .buttonStyle(MemoryButtonStyle(isActive: showMemorySettings))
    }

    private var closeButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                isPresented = false
            }
        }) {
            Circle()
                .fill(Color(white: 0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // NUEVO: Área de mensajes de chat
    private var chatMessagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    // Mostrar mensajes si hay
                    if !chatMessages.isEmpty {
                        ForEach(chatMessages) { message in
                            ChatBubble(message: message) { place in
                                // Cerrar el teclado
                                isMessageFocused = false

                                // Cerrar el chat
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    isPresented = false
                                }

                                // Usar el callback para mostrar direcciones en WorldCupMapView
                                // Esto configurará el marcador y abrirá el modal de direcciones
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    onShowDirections(place.coordinate, place.name)
                                }
                            }
                            .id(message.id)
                        }
                    }

                    // Indicador de carga
                    if claudeService.isLoading {
                        HStack {
                            ProgressView()
                                .tint(Color(hex: "#00D084"))
                            Text("Pensando...")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .onChange(of: chatMessages.count) { oldValue, newValue in
                // Auto-scroll al último mensaje
                if let lastMessage = chatMessages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // NUEVO: Barra de input de chat
    private var chatInputBar: some View {
        HStack(spacing: 12) {
            TextField("", text: $messageText, prompt: Text("Pregunta lo que quieras...").foregroundColor(.white.opacity(0.3)))
                .font(.system(size: 17))
                .foregroundColor(.white)
                .focused($isMessageFocused)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color(white: 0.12))
                .cornerRadius(28)
                .onSubmit {
                    sendMessage()
                }

            // Botón enviar
            Button(action: {
                sendMessage()
            }) {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "#C8FF00"), Color(hex: "#00D084")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                    )
            }
            .disabled(messageText.isEmpty || claudeService.isLoading)
            .opacity(messageText.isEmpty ? 0.5 : 1.0)
        }
    }

    // NUEVO: Vista del overlay de fondo
    private func backgroundOverlay(for geometry: GeometryProxy) -> some View {
        ZStack {
            // Blur del fondo
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .opacity(showContent ? 1 : 0)

            // Overlay oscuro sutil
            Color.black.opacity(overlayOpacity(for: geometry.size.height))
                .ignoresSafeArea()
                .opacity(showContent ? 1 : 0)
        }
    }

    // Calcular opacidad del overlay según el estado - más sutil con blur
    private func overlayOpacity(for screenHeight: CGFloat) -> Double {
        switch sheetState {
        case .medium: return 0.2
        case .full: return 0.35
        }
    }

    // Manejar el final del arrastre y hacer snap al estado más cercano
    private func handleDragEnd(translation: CGFloat, screenHeight: CGFloat) {
        let currentHeight = sheetState.height(for: screenHeight)
        let newHeight = currentHeight - translation

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            // Si arrastra hacia abajo más de 150px desde medium, cerrar
            if sheetState == .medium && translation > 150 {
                isPresented = false
                dragOffset = 0
                return
            }

            // Determinar el estado más cercano entre medium y full
            let mediumHeight = SheetState.medium.height(for: screenHeight)
            let fullHeight = SheetState.full.height(for: screenHeight)

            let distanceToMedium = abs(newHeight - mediumHeight)
            let distanceToFull = abs(newHeight - fullHeight)

            if distanceToMedium < distanceToFull {
                sheetState = .medium
            } else {
                sheetState = .full
            }

            dragOffset = 0
        }
    }

    // NUEVO: Enviar mensaje a Claude
    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        // Verificar que hay API key
        guard APIConfiguration.shared.hasClaudeAPIKey else {
            showAPIKeyAlert = true
            return
        }

        let userMessage = messageText
        messageText = ""

        // Agregar mensaje del usuario
        chatMessages.append(ChatMessage(text: userMessage, isUser: true))

        // Enviar a Claude API
        Task {
            do {
                let response = try await claudeService.sendMessage(userMessage, conversationHistory: chatMessages.filter { !$0.isUser || $0.text != userMessage })

                await MainActor.run {
                    chatMessages.append(ChatMessage(text: response, isUser: false))
                }
            } catch {
                await MainActor.run {
                    chatMessages.append(ChatMessage(
                        text: "Lo siento, hubo un error al procesar tu mensaje: \(error.localizedDescription)",
                        isUser: false
                    ))
                }
            }
        }
    }
}

// Botón de modo (History, Basic, Memory)
struct ModeButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let backgroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isSelected ? textColor : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? backgroundColor : Color(white: 0.15))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // Color de texto dinámico según el color de fondo
    private var textColor: Color {
        // Si es el verde lima (#C8FF00), usar negro
        // Para los demás colores, usar blanco
        if backgroundColor == Color(hex: "#C8FF00") {
            return .black
        } else {
            return .white
        }
    }
}

// Estilo de botón con efecto de escala y brillo al presionar
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .brightness(configuration.isPressed ? 0.15 : 0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Estilo de botón History - cambia a verde al presionar o cuando está activo
struct HistoryButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shouldHighlight = configuration.isPressed || isActive

        return configuration.label
            .background(
                Capsule()
                    .fill(shouldHighlight ? Color(hex: "#00D084") : Color(white: 0.15))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// Estilo de botón Memory - cambia a amarillo/lima al presionar o cuando está activo
struct MemoryButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shouldHighlight = configuration.isPressed || isActive

        return configuration.label
            .foregroundColor(shouldHighlight ? .black : .white)
            .background(
                Circle()
                    .fill(shouldHighlight ? Color(hex: "#C8FF00") : Color(white: 0.15))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// Chip de sugerencia
struct SuggestionChip: View {
    let text: String

    var body: some View {
        Button(action: {
            print("💡 Sugerencia seleccionada: \(text)")
        }) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(
                    Capsule()
                        .fill(Color(white: 0.15))
                )
        }
    }
}

// Vista de historial de búsquedas
struct HistoryView: View {
    @Binding var isPresented: Bool
    @State private var searchHistoryText: String = ""
    @FocusState private var isHistorySearchFocused: Bool

    // Datos de ejemplo del historial
    @State private var searchHistory: [SearchHistoryItem] = [
        SearchHistoryItem(query: "Restaurantes mexicanos cerca", timestamp: Date().addingTimeInterval(-3600)),
        SearchHistoryItem(query: "Estadio Azteca dirección", timestamp: Date().addingTimeInterval(-7200)),
        SearchHistoryItem(query: "Mejores tacos en Guadalajara", timestamp: Date().addingTimeInterval(-86400)),
        SearchHistoryItem(query: "Transporte público CDMX", timestamp: Date().addingTimeInterval(-172800)),
        SearchHistoryItem(query: "Hoteles cerca del estadio", timestamp: Date().addingTimeInterval(-259200)),
        SearchHistoryItem(query: "Clima en Monterrey", timestamp: Date().addingTimeInterval(-345600)),
        SearchHistoryItem(query: "Vuelos a Toronto", timestamp: Date().addingTimeInterval(-432000))
    ]

    var filteredHistory: [SearchHistoryItem] {
        if searchHistoryText.isEmpty {
            return searchHistory
        } else {
            return searchHistory.filter { $0.query.localizedCaseInsensitiveContains(searchHistoryText) }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fondo oscuro
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    }

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 50)

                    // Panel principal
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            // Botón volver
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    isPresented = false
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color(white: 0.15))
                                    )
                            }

                            Spacer()

                            Text("Historial de Búsquedas")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)

                            Spacer()

                            // Botón limpiar historial
                            Button(action: {
                                withAnimation {
                                    searchHistory.removeAll()
                                }
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color(white: 0.15))
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                        // Buscador para filtrar historial
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.5))

                            TextField("", text: $searchHistoryText, prompt: Text("Buscar en historial...").foregroundColor(.white.opacity(0.3)))
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .focused($isHistorySearchFocused)

                            if !searchHistoryText.isEmpty {
                                Button(action: {
                                    searchHistoryText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(white: 0.12))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                        // Lista de historial
                        ScrollView {
                            VStack(spacing: 0) {
                                if filteredHistory.isEmpty {
                                    // Estado vacío
                                    VStack(spacing: 16) {
                                        Image(systemName: searchHistoryText.isEmpty ? "clock" : "magnifyingglass")
                                            .font(.system(size: 48))
                                            .foregroundColor(.white.opacity(0.3))
                                            .padding(.top, 60)

                                        Text(searchHistoryText.isEmpty ? "No hay historial" : "No se encontraron resultados")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.7))

                                        Text(searchHistoryText.isEmpty ? "Tus búsquedas aparecerán aquí" : "Intenta con otra búsqueda")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                } else {
                                    ForEach(filteredHistory) { item in
                                        HistoryItemRow(item: item) {
                                            // Acción al presionar un item
                                            print("📝 Búsqueda seleccionada: \(item.query)")
                                        } onDelete: {
                                            // Eliminar item
                                            withAnimation {
                                                if let index = searchHistory.firstIndex(where: { $0.id == item.id }) {
                                                    searchHistory.remove(at: index)
                                                }
                                            }
                                        }

                                        if item.id != filteredHistory.last?.id {
                                            Divider()
                                                .background(Color.white.opacity(0.1))
                                                .padding(.leading, 60)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 30)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: geometry.size.height - 50)
                    .background(Color.black)
                    .clipShape(
                        RoundedCorner(radius: 30, corners: [.topLeft, .topRight])
                    )
                }
            }
        }
        .onAppear {
            // Auto-enfocar el buscador
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isHistorySearchFocused = true
            }
        }
    }
}

// Modelo para items del historial
struct SearchHistoryItem: Identifiable {
    let id = UUID()
    let query: String
    let timestamp: Date

    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "es")
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// Row para cada item del historial
struct HistoryItemRow: View {
    let item: SearchHistoryItem
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icono
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#00D084"))
                    .frame(width: 24)

                // Texto
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.query)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    Text(item.formattedTime)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Botón eliminar
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Vista de configuración de Memory
struct MemorySettingsView: View {
    @Binding var isPresented: Bool

    // Estados para las preferencias (con datos de ejemplo para Emi Cruz)
    @State private var favoriteFoods: Set<String> = ["Mexican", "Italian", "Japanese", "Thai"]
    @State private var coffeePreference: String? = "Local Coffee Shops"
    @State private var dietaryRestrictions: Set<String> = ["No Restrictions"]
    @State private var specialConsiderations: Set<String> = []
    @State private var measurementUnit: String = "Kilometers"
    @State private var showProfileView: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fondo oscuro
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    }

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 50)

                    // Panel principal
                    VStack(spacing: 0) {
                        // Header con icono de usuario
                        HStack {
                            Spacer()

                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    showProfileView = true
                                }
                            }) {
                                Circle()
                                    .fill(Color(white: 0.15))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white.opacity(0.7))
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                        // Título principal
                        Text("Update your Memory")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)

                        // Contenido scrollable
                        ScrollView {
                            VStack(spacing: 32) {
                                // Sección: Favorite Foods
                                MemorySection(
                                    title: "Favorite Foods",
                                    subtitle: "Let us know what types of foods you like most so we can show you more relevant suggestions faster."
                                ) {
                                    VStack(spacing: 0) {
                                        MemoryCheckboxItem(emoji: "🍝", title: "Italian", isSelected: favoriteFoods.contains("Italian")) {
                                            toggleSelection(&favoriteFoods, "Italian")
                                        }
                                        MemoryCheckboxItem(emoji: "🌮", title: "Mexican", isSelected: favoriteFoods.contains("Mexican")) {
                                            toggleSelection(&favoriteFoods, "Mexican")
                                        }
                                        MemoryCheckboxItem(emoji: "🍱", title: "Japanese", isSelected: favoriteFoods.contains("Japanese")) {
                                            toggleSelection(&favoriteFoods, "Japanese")
                                        }
                                        MemoryCheckboxItem(emoji: "🇨🇳", title: "Chinese", isSelected: favoriteFoods.contains("Chinese")) {
                                            toggleSelection(&favoriteFoods, "Chinese")
                                        }
                                        MemoryCheckboxItem(emoji: "🫒", title: "Mediterranean", isSelected: favoriteFoods.contains("Mediterranean")) {
                                            toggleSelection(&favoriteFoods, "Mediterranean")
                                        }
                                        MemoryCheckboxItem(emoji: "🇹🇭", title: "Thai", isSelected: favoriteFoods.contains("Thai")) {
                                            toggleSelection(&favoriteFoods, "Thai")
                                        }
                                        MemoryCheckboxItem(emoji: "🐌", title: "French", isSelected: favoriteFoods.contains("French")) {
                                            toggleSelection(&favoriteFoods, "French")
                                        }
                                        MemoryCheckboxItem(emoji: "🍔", title: "American", isSelected: favoriteFoods.contains("American")) {
                                            toggleSelection(&favoriteFoods, "American")
                                        }
                                        MemoryCheckboxItem(emoji: "🥙", title: "Middle Eastern", isSelected: favoriteFoods.contains("Middle Eastern")) {
                                            toggleSelection(&favoriteFoods, "Middle Eastern")
                                        }
                                        MemoryCheckboxItem(emoji: "🍜", title: "Vietnamese", isSelected: favoriteFoods.contains("Vietnamese")) {
                                            toggleSelection(&favoriteFoods, "Vietnamese")
                                        }
                                        MemoryCheckboxItem(emoji: "🇰🇷", title: "Korean", isSelected: favoriteFoods.contains("Korean")) {
                                            toggleSelection(&favoriteFoods, "Korean")
                                        }
                                    }
                                }

                                // Sección: Coffee Shop Preferences
                                MemorySection(
                                    title: "Coffee Shop Preferences",
                                    subtitle: "Any special considerations that would make your search experience much better?"
                                ) {
                                    VStack(spacing: 0) {
                                        MemoryCheckboxItem(emoji: "👨‍💼", title: "Large Chains (e.g. \"Starbucks\")", isSelected: coffeePreference == "Large Chains") {
                                            coffeePreference = coffeePreference == "Large Chains" ? nil : "Large Chains"
                                        }
                                        MemoryCheckboxItem(emoji: "😊", title: "Local Coffee Shops", isSelected: coffeePreference == "Local Coffee Shops") {
                                            coffeePreference = coffeePreference == "Local Coffee Shops" ? nil : "Local Coffee Shops"
                                        }
                                    }
                                }

                                // Sección: Dietary Considerations
                                MemorySection(
                                    title: "Dietary Considerations",
                                    subtitle: "Add any dietary preferences, so you get the right better follow up question suggestions."
                                ) {
                                    VStack(spacing: 0) {
                                        MemoryCheckboxItem(emoji: "🥦", title: "Vegan", isSelected: dietaryRestrictions.contains("Vegan")) {
                                            toggleSelection(&dietaryRestrictions, "Vegan")
                                        }
                                        MemoryCheckboxItem(emoji: "🥚", title: "Vegetarian", isSelected: dietaryRestrictions.contains("Vegetarian")) {
                                            toggleSelection(&dietaryRestrictions, "Vegetarian")
                                        }
                                        MemoryCheckboxItem(emoji: "🌾", title: "Gluten Free", isSelected: dietaryRestrictions.contains("Gluten Free")) {
                                            toggleSelection(&dietaryRestrictions, "Gluten Free")
                                        }
                                        MemoryCheckboxItem(emoji: "✨", title: "I Have No Dietary Restrictions", isSelected: dietaryRestrictions.contains("No Restrictions")) {
                                            toggleSelection(&dietaryRestrictions, "No Restrictions")
                                        }
                                    }
                                }

                                // Sección: Special Considerations
                                MemorySection(
                                    title: "Special Considerations",
                                    subtitle: "Any special considerations that would make your search experience much better?"
                                ) {
                                    VStack(spacing: 0) {
                                        MemoryCheckboxItem(emoji: "♿", title: "Wheelchair Accessible", isSelected: specialConsiderations.contains("Wheelchair Accessible")) {
                                            toggleSelection(&specialConsiderations, "Wheelchair Accessible")
                                        }
                                        MemoryCheckboxItem(emoji: "🎧", title: "Sensory Sensitivity", isSelected: specialConsiderations.contains("Sensory Sensitivity")) {
                                            toggleSelection(&specialConsiderations, "Sensory Sensitivity")
                                        }
                                    }
                                }

                                // Sección: Measurement Preferences
                                MemorySection(
                                    title: "Measurement Preferences",
                                    subtitle: "Do you have a preference for miles or kilometers?"
                                ) {
                                    VStack(spacing: 0) {
                                        MemoryCheckboxItem(emoji: "🇺🇸", title: "Miles", isSelected: measurementUnit == "Miles") {
                                            measurementUnit = "Miles"
                                        }
                                        MemoryCheckboxItem(emoji: "🌍", title: "Kilometers", isSelected: measurementUnit == "Kilometers") {
                                            measurementUnit = "Kilometers"
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }

                        // Botón Update Memory
                        VStack(spacing: 0) {
                            Divider()
                                .background(Color.white.opacity(0.1))

                            Button(action: {
                                // Guardar preferencias
                                print("💾 Guardando preferencias de Memory...")
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    isPresented = false
                                }
                            }) {
                                Text("Update Memory")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(hex: "#C8FF00"))
                                    )
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .background(Color.black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: geometry.size.height - 50)
                    .background(Color.black)
                    .clipShape(
                        RoundedCorner(radius: 30, corners: [.topLeft, .topRight])
                    )
                }
            }
        }
        .overlay(
            // Modal de perfil
            Group {
                if showProfileView {
                    ProfileView(
                        isPresented: $showProfileView,
                        favoriteFoods: favoriteFoods,
                        coffeePreference: coffeePreference,
                        dietaryRestrictions: dietaryRestrictions,
                        specialConsiderations: specialConsiderations,
                        measurementUnit: measurementUnit
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(1002)
                }
            }
        )
    }

    private func toggleSelection(_ set: inout Set<String>, _ item: String) {
        if set.contains(item) {
            set.remove(item)
        } else {
            set.insert(item)
        }
    }
}

// Sección de Memory con título y contenido
struct MemorySection<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Text(subtitle)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)

            content
        }
    }
}

// Item de checkbox para Memory
struct MemoryCheckboxItem: View {
    let emoji: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 24))

                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.white)

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.blue : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Vista de Perfil del Usuario
struct ProfileView: View {
    @Binding var isPresented: Bool
    let favoriteFoods: Set<String>
    let coffeePreference: String?
    let dietaryRestrictions: Set<String>
    let specialConsiderations: Set<String>
    let measurementUnit: String

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fondo oscuro
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    }

                VStack(spacing: 0) {
                    // Panel principal
                    VStack(spacing: 0) {
                        // Espacio para el safe area
                        Rectangle()
                            .fill(Color.black)
                            .frame(height: geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top + 10 : 50)

                        // Header con botón de cerrar - debajo del safe area
                        HStack {
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    isPresented = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color(white: 0.15))
                                    )
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 8)

                        // Perfil: Nombre grande e icono
                        HStack(spacing: 16) {
                            // Foto de perfil del usuario
                            if let userImage = UIImage(named: "User") {
                                Image(uiImage: userImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color(hex: "#C8FF00"), Color(hex: "#00D084")]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 3
                                            )
                                    )
                            } else {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color(hex: "#C8FF00"), Color(hex: "#00D084")]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.black)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                // Nombre en grande
                                Text("Emi Cruz")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)

                                // Nacionalidad con bandera
                                HStack(spacing: 6) {
                                    Text("🇲🇽")
                                        .font(.system(size: 20))

                                    Text("México")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)

                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)

                        // Contenido scrollable con información de memoria
                        ScrollView {
                            VStack(spacing: 32) {
                                // Sección: Favorite Foods
                                if !favoriteFoods.isEmpty {
                                    ProfileInfoSection(title: "Favorite Foods", icon: "fork.knife") {
                                        VStack(alignment: .leading, spacing: 12) {
                                            ForEach(Array(favoriteFoods).sorted(), id: \.self) { food in
                                                ProfileInfoItem(text: food, emoji: emojiForFood(food))
                                            }
                                        }
                                    }
                                }

                                // Sección: Coffee Shop Preference
                                if let coffee = coffeePreference {
                                    ProfileInfoSection(title: "Coffee Shop Preference", icon: "cup.and.saucer.fill") {
                                        ProfileInfoItem(text: coffee, emoji: coffee == "Large Chains" ? "👨‍💼" : "😊")
                                    }
                                }

                                // Sección: Dietary Considerations
                                if !dietaryRestrictions.isEmpty {
                                    ProfileInfoSection(title: "Dietary Considerations", icon: "leaf.fill") {
                                        VStack(alignment: .leading, spacing: 12) {
                                            ForEach(Array(dietaryRestrictions).sorted(), id: \.self) { restriction in
                                                ProfileInfoItem(text: restriction, emoji: emojiForDietary(restriction))
                                            }
                                        }
                                    }
                                }

                                // Sección: Special Considerations
                                if !specialConsiderations.isEmpty {
                                    ProfileInfoSection(title: "Special Considerations", icon: "star.fill") {
                                        VStack(alignment: .leading, spacing: 12) {
                                            ForEach(Array(specialConsiderations).sorted(), id: \.self) { consideration in
                                                ProfileInfoItem(text: consideration, emoji: consideration == "Wheelchair Accessible" ? "♿" : "🎧")
                                            }
                                        }
                                    }
                                }

                                // Sección: Measurement Unit
                                ProfileInfoSection(title: "Measurement Preference", icon: "ruler.fill") {
                                    ProfileInfoItem(text: measurementUnit, emoji: measurementUnit == "Miles" ? "🇺🇸" : "🌍")
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                }
            }
        }
    }

    // Helper para obtener emoji de comida
    private func emojiForFood(_ food: String) -> String {
        switch food {
        case "Italian": return "🍝"
        case "Mexican": return "🌮"
        case "Japanese": return "🍱"
        case "Chinese": return "🇨🇳"
        case "Mediterranean": return "🫒"
        case "Thai": return "🇹🇭"
        case "French": return "🐌"
        case "American": return "🍔"
        case "Middle Eastern": return "🥙"
        case "Vietnamese": return "🍜"
        case "Korean": return "🇰🇷"
        default: return "🍽️"
        }
    }

    // Helper para obtener emoji de restricciones dietéticas
    private func emojiForDietary(_ restriction: String) -> String {
        switch restriction {
        case "Vegan": return "🥦"
        case "Vegetarian": return "🥚"
        case "Gluten Free": return "🌾"
        case "No Restrictions": return "✨"
        default: return "🍽️"
        }
    }
}

// Sección de información del perfil
struct ProfileInfoSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "#C8FF00"))

                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Item de información del perfil
struct ProfileInfoItem: View {
    let text: String
    let emoji: String

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 24))

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.12))
        )
    }
}

// Modelo de mensaje de chat
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

// Burbuja de chat
struct ChatBubble: View {
    let message: ChatMessage
    var onPlaceSelected: ((PlaceLocation) -> Void)?

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            if message.isUser {
                // Mensaje del usuario (texto simple)
                Text(message.text)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#C8FF00"), Color(hex: "#00D084")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            } else {
                // Mensaje de Claude (con lugares clickeables)
                ClaudeMessageView(message: message.text) { place in
                    onPlaceSelected?(place)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.15), Color(white: 0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }

            if !message.isUser {
                Spacer()
            }
        }
    }
}

#Preview {
    AISearchView(
        isPresented: .constant(true),
        selectedCategory: "coffee",
        onNavigateToLocation: { _, _, _ in },
        onShowDirections: { _, _ in }
    )
}
