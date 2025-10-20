//
//  ContentView.swift
//  Atenea
//
//  Created by Emilio Cruz Vargas on 10/10/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var collectionManager = StickerCollectionManager()
    @State private var lastCollectedVenue: WorldCupVenue?
    @State private var showCollectionAnimation = false
    @State private var showSplash = true
    @State private var showOnboarding = true
    @State private var showLogin = true
    @State private var isLoggedIn = false
    @State private var showTutorial = true

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if showSplash {
                    // Mostrar splash screen
                    SplashScreenView(showSplash: $showSplash)
                } else if showOnboarding {
                    // Mostrar onboarding después del splash
                    OnboardingView(showOnboarding: $showOnboarding)
                } else if !isLoggedIn {
                    // Mostrar login después del onboarding
                    LoginView(isLoggedIn: $isLoggedIn)
                        .transition(.move(edge: .bottom))
                } else {
                    // Contenido principal según el tab seleccionado
                    Group {
                        switch selectedTab {
                        case 0:
                            WorldCupMapView(
                                selectedTab: $selectedTab,
                                collectionManager: collectionManager,
                                lastCollectedVenue: $lastCollectedVenue,
                                showCollectionAnimation: $showCollectionAnimation
                            )
                        case 1:
                            CommunityView(selectedTab: $selectedTab)
                        case 2:
                            StickerAlbumView(
                                selectedTab: $selectedTab,
                                collectionManager: collectionManager,
                                lastCollectedVenue: $lastCollectedVenue,
                                showCollectionAnimation: $showCollectionAnimation
                            )
                        default:
                            WorldCupMapView(
                                selectedTab: $selectedTab,
                                collectionManager: collectionManager,
                                lastCollectedVenue: $lastCollectedVenue,
                                showCollectionAnimation: $showCollectionAnimation
                            )
                        }
                    }

                    // Tutorial con spotlight después del onboarding
                    if showTutorial {
                        SpotlightTutorialView(
                            showTutorial: $showTutorial,
                            steps: SpotlightTutorialView.createDefaultSteps(screenSize: geometry.size)
                        )
                        .zIndex(1000)
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
}

// Vista de Comunidad
struct CommunityView: View {
    @State private var selectedFilter = LocalizedString("community.filter.all")
    @Binding var selectedTab: Int
    @StateObject private var postService = PostService.shared

    var filters: [String] {
        [
            LocalizedString("community.filter.all"),
            LocalizedString("community.filter.worldCup"),
            LocalizedString("community.filter.trending"),
            LocalizedString("community.filter.creator")
        ]
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Fondo con gradiente
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.45),
                        Color(red: 0.2, green: 0.3, blue: 0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header con filtros
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(filters, id: \.self) { filter in
                                FilterChip(
                                    title: filter,
                                    isSelected: selectedFilter == filter,
                                    icon: filter == LocalizedString("community.filter.creator") ? "star.fill" : nil
                                ) {
                                    selectedFilter = filter
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .background(Color.white.opacity(0.1))

                    // Feed de la comunidad
                    if postService.isLoading && postService.posts.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text(LocalizedString("status.loadingPosts"))
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline)
                            Spacer()
                        }
                    } else if let error = postService.errorMessage {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.6))
                            Text(LocalizedString("status.errorLoadingPosts"))
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            Button(LocalizedString("action.retry")) {
                                Task {
                                    await postService.refreshPosts()
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            Spacer()
                        }
                    } else if postService.posts.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "newspaper.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.6))
                            Text(LocalizedString("status.noPostsAvailable"))
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredPosts) { post in
                                    CommunityPostCard(post: post)
                                }
                            }
                            .padding(.vertical, 20)
                            .padding(.bottom, 100)
                        }
                        .refreshable {
                            await postService.refreshPosts()
                        }
                    }
                }

                // Tab Bar flotante en la parte inferior
                VStack {
                    Spacer()
                    SimpleTabBar(selectedTab: $selectedTab)
                        .background(Color.black)
                        .cornerRadius(30, corners: [.topLeft, .topRight])
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle(LocalizedString("tab.community"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Actualizar posts cada vez que se abre el tab
                Task {
                    await postService.fetchPosts()
                }
            }
        }
    }

    // MARK: - Filtered Posts
    private var filteredPosts: [CommunityPost] {
        let worldCupFilter = LocalizedString("community.filter.worldCup")
        let trendingFilter = LocalizedString("community.filter.trending")
        let creatorFilter = LocalizedString("community.filter.creator")

        switch selectedFilter {
        case worldCupFilter:
            return postService.posts.filter { $0.keywords.lowercased().contains("fifaworldcup") || $0.keywords.lowercased().contains("weare26") }
        case trendingFilter:
            return postService.posts.sorted { $0.id > $1.id } // Más recientes primero
        case creatorFilter:
            return postService.posts.filter { $0.username == "m_de_milo" }
        default:
            return postService.posts
        }
    }
}

// Chip de filtro
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .medium)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(isSelected ? 0.5 : 0.2), lineWidth: 1)
                    )
            )
        }
    }
}

// Tarjeta de post de comunidad
struct CommunityPostCard: View {
    let post: CommunityPost
    @State private var isLiked = false
    @State private var imageData: Data?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header del post
            HStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#E1306C"),
                                Color(hex: "#FD1D1D"),
                                Color(hex: "#F56040")
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(post.formattedDate)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Link(destination: URL(string: post.url) ?? URL(string: "https://instagram.com")!) {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Imagen del post
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 300)

                if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipped()
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)
                        Text(LocalizedString("status.loading"))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .task {
                await loadImage()
            }

            // Caption
            Text(post.content)
                .font(.body)
                .foregroundColor(.white)
                .lineLimit(3)
                .padding(.horizontal, 16)

            // Keywords/Tags
            if !post.keywordArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(post.keywordArray, id: \.self) { keyword in
                            Text("#\(keyword)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.15))
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            // Acciones
            HStack(spacing: 20) {
                Button(action: { isLiked.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .white)
                    }
                }

                Button(action: {}) {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.white)
                }

                Spacer()

                Text(post.source.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.6))
            }
            .font(.title3)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Load Image
    private func loadImage() async {
        guard let url = URL(string: post.image) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            await MainActor.run {
                self.imageData = data
            }
        } catch {
            print("❌ Error al cargar imagen: \(error)")
        }
    }
}

// Vista de Álbum de Pegatinas tipo Panini
struct StickerAlbumView: View {
    @Binding var selectedTab: Int
    @ObservedObject var collectionManager: StickerCollectionManager
    @Binding var lastCollectedVenue: WorldCupVenue?
    @Binding var showCollectionAnimation: Bool
    @State private var currentPageIndex: Int = 0
    @State private var showSections: Bool = false
    @State private var selectedSection: AlbumSection?
    @State private var showPaniniAlbum: Bool = false

    let albumPages = AlbumDataGenerator.generateAlbum()

    var totalStickers: Int {
        albumPages.reduce(0) { $0 + $1.stickerSlots.count }
    }

    var progress: Double {
        Double(collectionManager.collectedStickers.count) / Double(totalStickers)
    }

    var body: some View {
        ZStack {
            // Fondo con textura tipo papel
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.94, blue: 0.92),
                    Color(red: 0.92, green: 0.90, blue: 0.88)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header con progreso
                albumHeader

                // Navegación de páginas
                if showSections {
                    sectionGridView
                } else {
                    albumPageView
                }
            }

            // Tab Bar flotante
            VStack {
                Spacer()
                SimpleTabBar(selectedTab: $selectedTab)
                    .background(Color.black)
                    .cornerRadius(30, corners: [.topLeft, .topRight])
            }
            .ignoresSafeArea(edges: .bottom)

            // Modal del Álbum Panini
            if showPaniniAlbum {
                PaniniAlbumView(isPresented: $showPaniniAlbum)
                    .zIndex(1000)
                    .transition(.opacity)
            }
        }
        .onChange(of: lastCollectedVenue) { oldValue, newValue in
            if let venue = newValue {
                navigateToVenuePage(venue)
            }
        }
    }

    // MARK: - Navigate to Venue Page
    private func navigateToVenuePage(_ venue: WorldCupVenue) {
        // Encontrar el índice de la página de esta sede
        if let venueIndex = WorldCupVenue.allVenues.firstIndex(where: { $0.id == venue.id }) {
            // Las páginas de sedes empiezan en la página 4 (después de intro)
            let targetPageIndex = 4 + venueIndex

            // Cerrar vista de secciones si está abierta
            showSections = false

            // Navegar a la página con animación
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentPageIndex = targetPageIndex
                }

                // Resetear después de mostrar
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    lastCollectedVenue = nil
                    showCollectionAnimation = false
                }
            }
        }
    }

    // MARK: - Album Header
    private var albumHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        showSections.toggle()
                    }
                }) {
                    Image(systemName: showSections ? "book.closed.fill" : "square.grid.2x2.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#00D084"))
                        .frame(width: 40, height: 40)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedString("worldcup.title"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "#1a1a1a"))
                    Text("\(collectionManager.collectedStickers.count) \(LocalizedString("album.of")) \(totalStickers) \(LocalizedString("album.stickers"))")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Spacer()

                // Botón especial del Álbum Panini 2022
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        showPaniniAlbum = true
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)

                        Text("2022")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 50, height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#FF4500"),
                                Color(hex: "#FF6B35")
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color(hex: "#FF4500").opacity(0.4), radius: 8, x: 0, y: 4)
                }

                // Contador de páginas
                if !showSections {
                    Text("\(currentPageIndex + 1)/\(albumPages.count)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 70)

            // Barra de progreso
            ProgressBar(progress: progress)
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
        .background(
            Color.white.opacity(0.9)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
        )
    }

    // MARK: - Album Page View
    private var albumPageView: some View {
        TabView(selection: $currentPageIndex) {
            ForEach(Array(albumPages.enumerated()), id: \.element.id) { index, page in
                AlbumPageDetailView(
                    page: page,
                    collectionManager: collectionManager,
                    highlightNewStickers: shouldHighlightPage(index)
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .padding(.bottom, 100)
    }

    private func shouldHighlightPage(_ index: Int) -> Bool {
        guard showCollectionAnimation, let venue = lastCollectedVenue else {
            return false
        }

        if let venueIndex = WorldCupVenue.allVenues.firstIndex(where: { $0.id == venue.id }) {
            let targetPageIndex = 4 + venueIndex
            return index == targetPageIndex
        }

        return false
    }

    // MARK: - Section Grid View
    private var sectionGridView: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(AlbumSection.allCases) { section in
                    SectionCard(
                        section: section,
                        progress: sectionProgress(for: section)
                    ) {
                        // Navegar a la primera página de la sección
                        if let firstPageIndex = albumPages.firstIndex(where: { $0.section == section }) {
                            withAnimation {
                                currentPageIndex = firstPageIndex
                                showSections = false
                            }
                        }
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 100)
        }
    }

    private func sectionProgress(for section: AlbumSection) -> Double {
        let sectionPages = albumPages.filter { $0.section == section }
        let totalStickersInSection = sectionPages.reduce(0) { $0 + $1.stickerSlots.count }
        let collectedInSection = sectionPages.reduce(0) { partialResult, page in
            partialResult + page.stickerSlots.filter { collectionManager.hasSticker($0.stickerId) }.count
        }
        return totalStickersInSection > 0 ? Double(collectedInSection) / Double(totalStickersInSection) : 0
    }
}

// MARK: - Album Page Detail View
struct AlbumPageDetailView: View {
    let page: AlbumPage
    @ObservedObject var collectionManager: StickerCollectionManager
    var highlightNewStickers: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header de la página
                VStack(spacing: 8) {
                    Text(page.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "#1a1a1a"))

                    if let subtitle = page.subtitle {
                        Text(subtitle)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }

                    // Badge de sección
                    HStack(spacing: 8) {
                        Image(systemName: page.section.icon)
                            .font(.system(size: 12))
                        Text(page.section.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(page.section.color)
                    )
                }
                .padding(.top, 20)

                // Grid de stickers según el layout
                stickerGrid
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var stickerGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(page.stickerSlots) { slot in
                StickerSlotView(
                    stickerId: slot.stickerId,
                    isSpecial: slot.isSpecialSlot,
                    isCollected: collectionManager.hasSticker(slot.stickerId),
                    shouldHighlight: highlightNewStickers && collectionManager.hasSticker(slot.stickerId),
                    label: slot.label
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        collectionManager.collectSticker(slot.stickerId)
                    }
                }
            }
        }
    }
}

// MARK: - Sticker Slot View
struct StickerSlotView: View {
    let stickerId: Int
    let isSpecial: Bool
    let isCollected: Bool
    var shouldHighlight: Bool = false
    var label: String? = nil
    let onTap: () -> Void

    @State private var showPeelEffect = false
    @State private var highlightPulse = false

    // Obtener el venue correspondiente si es un sticker de sede (14+)
    private var venue: WorldCupVenue? {
        guard stickerId >= 14 else { return nil }
        let venueIndex = stickerId - 14
        guard venueIndex < WorldCupVenue.allVenues.count else { return nil }
        return WorldCupVenue.allVenues[venueIndex]
    }

    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                if !isCollected {
                    showPeelEffect = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onTap()
                        showPeelEffect = false
                    }
                }
            }) {
                ZStack {
                // Anillo de resaltado pulsante para stickers recién agregados
                if shouldHighlight && isCollected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#00D084"),
                                    Color(hex: "#C8FF00")
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .scaleEffect(highlightPulse ? 1.1 : 1.0)
                        .opacity(highlightPulse ? 0.3 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                            value: highlightPulse
                        )
                        .onAppear {
                            highlightPulse = true
                        }

                    // Brillo exterior adicional
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#00D084").opacity(0.2),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 1,
                                endRadius: 80
                            )
                        )
                        .scaleEffect(highlightPulse ? 1.3 : 1.0)
                        .opacity(highlightPulse ? 0.0 : 0.6)
                        .animation(
                            Animation.easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false),
                            value: highlightPulse
                        )
                }

                // Fondo del slot
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.96, green: 0.96, blue: 0.94),
                                Color(red: 0.93, green: 0.93, blue: 0.91)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                shouldHighlight && isCollected ?
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "#00D084"),
                                            Color(hex: "#C8FF00")
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.gray.opacity(0.3),
                                            Color.gray.opacity(0.3)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                style: StrokeStyle(
                                    lineWidth: shouldHighlight && isCollected ? 3 : 2,
                                    dash: shouldHighlight && isCollected ? [] : [8, 4]
                                )
                            )
                    )

                if isCollected {
                    // Sticker coleccionado
                    VStack(spacing: 8) {
                        ZStack {
                            // Efecto de brillo para especiales
                            if isSpecial {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "#FFD700").opacity(0.3),
                                                Color.clear
                                            ]),
                                            center: .center,
                                            startRadius: 10,
                                            endRadius: 40
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                            }

                            // Mostrar imagen real del poster o ícono genérico
                            if let venue = venue {
                                Image(venue.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 90, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "soccerball")
                                    .font(.system(size: 40))
                                    .foregroundColor(isSpecial ? Color(hex: "#FFD700") : Color(hex: "#00D084"))
                            }
                        }

                        Text("#\(stickerId)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(4)

                        // Badge "NUEVO" para stickers destacados
                        if shouldHighlight {
                            Text(LocalizedString("album.new"))
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "#00D084"))
                                )
                                .scaleEffect(highlightPulse ? 1.05 : 0.95)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever(autoreverses: true),
                                    value: highlightPulse
                                )
                        }
                    }
                    .scaleEffect(showPeelEffect ? 1.1 : (shouldHighlight ? 1.05 : 1.0))
                    .rotation3DEffect(
                        .degrees(showPeelEffect ? 10 : 0),
                        axis: (x: 1, y: 1, z: 0)
                    )
                } else {
                    // Slot vacío
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.gray.opacity(0.3))

                        Text("#\(stickerId)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
            }
            .frame(height: 140)
            .shadow(
                color: shouldHighlight && isCollected ? Color(hex: "#00D084").opacity(0.4) : Color.clear,
                radius: shouldHighlight && isCollected ? 10 : 0,
                x: 0,
                y: 0
            )
            }
            .buttonStyle(PlainButtonStyle())

            // Label del slot (nombre de la sede)
            if let label = label {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#1a1a1a"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Section Card
struct SectionCard: View {
    let section: AlbumSection
    let progress: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: section.icon)
                        .font(.system(size: 32))
                        .foregroundColor(section.color)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(section.color.opacity(0.15))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(section.rawValue)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "#1a1a1a"))

                        Text("\(Int(progress * 100))% \(LocalizedString("album.completed"))")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                }

                // Barra de progreso de la sección
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(section.color)
                            .frame(width: geometry.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 20)

                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#00D084"),
                                Color(hex: "#C8FF00")
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 20)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 20)
    }
}

// Tab Bar simple para otras vistas
struct SimpleTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            // Tab 1: Mapa
            SimpleTabBarItem(
                icon: "map.fill",
                title: LocalizedString("tab.map"),
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }

            // Tab 2: Comunidad
            SimpleTabBarItem(
                icon: "person.3.fill",
                title: LocalizedString("tab.community"),
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }

            // Tab 3: Álbum
            SimpleTabBarItem(
                icon: "square.grid.3x3.fill",
                title: LocalizedString("tab.album"),
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .padding(.bottom, 20)
    }
}

// Item individual del Tab Bar simple
struct SimpleTabBarItem: View {
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

#Preview {
    ContentView()
}
