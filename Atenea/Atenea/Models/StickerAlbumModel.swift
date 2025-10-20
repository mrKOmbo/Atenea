//
//  StickerAlbumModel.swift
//  Atenea
//
//  Created by Claude on 10/15/25.
//

import SwiftUI
import MapKit
internal import Combine

// MARK: - Sticker Types
enum StickerType: String, Codable {
    case badge        // Escudos
    case player       // Jugadores
    case stadium      // Estadios
    case special      // Especiales (foil/brillantes)
    case emblem       // Emblemas
    case legend       // Leyendas
}

// MARK: - Album Sections
enum AlbumSection: String, CaseIterable, Identifiable {
    case intro = "Introducción"
    case venues = "Sedes Mundial 2026"
    case groups = "Fase de Grupos"
    case teams = "Selecciones"
    case legends = "Leyendas"
    case special = "Especiales"
    case panini = "Álbum Panini"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .intro: return "trophy.fill"
        case .venues: return "building.2.fill"
        case .groups: return "list.bullet"
        case .teams: return "flag.fill"
        case .legends: return "star.fill"
        case .special: return "sparkles"
        case .panini: return "book.fill"
        }
    }

    var color: Color {
        switch self {
        case .intro: return Color(hex: "#FFD700")
        case .venues: return Color(hex: "#00D084")
        case .groups: return Color(hex: "#FF6B6B")
        case .teams: return Color(hex: "#4ECDC4")
        case .legends: return Color(hex: "#9D4EDD")
        case .special: return Color(hex: "#F72585")
        case .panini: return Color(hex: "#FF4500")
        }
    }
}

// MARK: - Sticker Model
struct Sticker: Identifiable {
    let id: UUID
    let number: Int
    let name: String
    let subtitle: String
    let type: StickerType
    let section: AlbumSection
    let isSpecial: Bool  // Foil/brillante
    let rarity: StickerRarity

    // Datos específicos según el tipo
    var venueId: UUID?
    var imageSystemName: String
    var gradient: [String]  // Hex colors para gradiente

    init(id: UUID = UUID(), number: Int, name: String, subtitle: String, type: StickerType, section: AlbumSection, isSpecial: Bool = false, rarity: StickerRarity = .common, venueId: UUID? = nil, imageSystemName: String = "photo", gradient: [String] = ["#667eea", "#764ba2"]) {
        self.id = id
        self.number = number
        self.name = name
        self.subtitle = subtitle
        self.type = type
        self.section = section
        self.isSpecial = isSpecial
        self.rarity = rarity
        self.venueId = venueId
        self.imageSystemName = imageSystemName
        self.gradient = gradient
    }
}

// MARK: - Sticker Rarity
enum StickerRarity: String, Codable {
    case common = "Común"
    case rare = "Rara"
    case epic = "Épica"
    case legendary = "Legendaria"

    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return Color(hex: "#FFD700")
        }
    }
}

// MARK: - Album Page Model
struct AlbumPage: Identifiable {
    let id: UUID
    let pageNumber: Int
    let section: AlbumSection
    let title: String
    let subtitle: String?
    let stickerSlots: [StickerSlot]
    let layoutType: PageLayout

    init(id: UUID = UUID(), pageNumber: Int, section: AlbumSection, title: String, subtitle: String? = nil, stickerSlots: [StickerSlot], layoutType: PageLayout = .standard) {
        self.id = id
        self.pageNumber = pageNumber
        self.section = section
        self.title = title
        self.subtitle = subtitle
        self.stickerSlots = stickerSlots
        self.layoutType = layoutType
    }
}

// MARK: - Sticker Slot (posición en página)
struct StickerSlot: Identifiable {
    let id: UUID
    let stickerId: Int  // Número del sticker
    let position: SlotPosition
    let isSpecialSlot: Bool  // Para foils/brillantes
    let label: String?  // Nombre/etiqueta del slot (ej: nombre de sede)

    init(id: UUID = UUID(), stickerId: Int, position: SlotPosition, isSpecialSlot: Bool = false, label: String? = nil) {
        self.id = id
        self.stickerId = stickerId
        self.position = position
        self.isSpecialSlot = isSpecialSlot
        self.label = label
    }
}

// MARK: - Slot Position
struct SlotPosition {
    let row: Int
    let column: Int
}

// MARK: - Page Layout Types
enum PageLayout {
    case standard      // 3x3 grid estándar
    case showcase      // 1 grande + varios pequeños
    case stadium       // Layout especial para estadios
    case team          // Layout para equipos (escudo + jugadores)
}

// MARK: - Album Data Generator
class AlbumDataGenerator {

    static func generateAlbum() -> [AlbumPage] {
        var pages: [AlbumPage] = []
        var stickerNumber = 1

        // SECCIÓN 1: Introducción (Páginas 1-4)
        pages.append(contentsOf: generateIntroPages(startingStickerNumber: &stickerNumber))

        // SECCIÓN 2: Sedes Mundial 2026 (Páginas 5-20)
        pages.append(contentsOf: generateVenuePages(startingStickerNumber: &stickerNumber))

        // SECCIÓN 3: Fase de Grupos (Páginas 21-36)
        pages.append(contentsOf: generateGroupPages(startingStickerNumber: &stickerNumber))

        // SECCIÓN 4: Selecciones (Páginas 37-84)
        pages.append(contentsOf: generateTeamPages(startingStickerNumber: &stickerNumber))

        // SECCIÓN 5: Leyendas (Páginas 85-88)
        pages.append(contentsOf: generateLegendPages(startingStickerNumber: &stickerNumber))

        // SECCIÓN 6: Especiales (Páginas 89-92)
        pages.append(contentsOf: generateSpecialPages(startingStickerNumber: &stickerNumber))

        // SECCIÓN 7: Álbum Panini (Páginas 93-100)
        pages.append(contentsOf: generatePaniniPages(startingStickerNumber: &stickerNumber))

        return pages
    }

    // MARK: - Intro Pages
    private static func generateIntroPages(startingStickerNumber: inout Int) -> [AlbumPage] {
        var pages: [AlbumPage] = []

        // Página 1: Portada/Trofeo
        let page1Slots = [
            StickerSlot(stickerId: startingStickerNumber, position: SlotPosition(row: 0, column: 1), isSpecialSlot: true),
        ]
        pages.append(AlbumPage(
            pageNumber: 1,
            section: .intro,
            title: "FIFA World Cup 2026™",
            subtitle: "El Trofeo Más Codiciado",
            stickerSlots: page1Slots,
            layoutType: .showcase
        ))
        startingStickerNumber += 1

        // Página 2: Emblema y Mascota
        let page2Slots = [
            StickerSlot(stickerId: startingStickerNumber, position: SlotPosition(row: 0, column: 0), isSpecialSlot: true),
            StickerSlot(stickerId: startingStickerNumber + 1, position: SlotPosition(row: 0, column: 1), isSpecialSlot: true),
            StickerSlot(stickerId: startingStickerNumber + 2, position: SlotPosition(row: 1, column: 0)),
            StickerSlot(stickerId: startingStickerNumber + 3, position: SlotPosition(row: 1, column: 1)),
        ]
        pages.append(AlbumPage(
            pageNumber: 2,
            section: .intro,
            title: "Identidad del Mundial",
            subtitle: "Emblema y Mascota Oficial",
            stickerSlots: page2Slots
        ))
        startingStickerNumber += 4

        // Página 3: Campeones anteriores
        let page3Slots = (0..<6).map { index in
            StickerSlot(
                stickerId: startingStickerNumber + index,
                position: SlotPosition(row: index / 2, column: index % 2),
                isSpecialSlot: true
            )
        }
        pages.append(AlbumPage(
            pageNumber: 3,
            section: .intro,
            title: "Campeones del Mundo",
            subtitle: "Últimos 6 Campeones",
            stickerSlots: page3Slots
        ))
        startingStickerNumber += 6

        // Página 4: Países anfitriones
        let page4Slots = [
            StickerSlot(stickerId: startingStickerNumber, position: SlotPosition(row: 0, column: 0), isSpecialSlot: true),
            StickerSlot(stickerId: startingStickerNumber + 1, position: SlotPosition(row: 0, column: 1), isSpecialSlot: true),
            StickerSlot(stickerId: startingStickerNumber + 2, position: SlotPosition(row: 1, column: 0), isSpecialSlot: true),
        ]
        pages.append(AlbumPage(
            pageNumber: 4,
            section: .intro,
            title: "Países Anfitriones",
            subtitle: "México, USA y Canadá",
            stickerSlots: page4Slots
        ))
        startingStickerNumber += 3

        return pages
    }

    // MARK: - Venue Pages
    private static func generateVenuePages(startingStickerNumber: inout Int) -> [AlbumPage] {
        var pages: [AlbumPage] = []
        let venues = WorldCupVenue.allVenues
        let venuesPerPage = 6 // 6 sedes por página en grid 2x3

        // Dividir las 16 sedes en páginas de 6
        let totalPages = Int(ceil(Double(venues.count) / Double(venuesPerPage)))

        for pageIndex in 0..<totalPages {
            let startIndex = pageIndex * venuesPerPage
            let endIndex = min(startIndex + venuesPerPage, venues.count)
            let venuesInPage = Array(venues[startIndex..<endIndex])

            var pageSlots: [StickerSlot] = []

            for (slotIndex, venue) in venuesInPage.enumerated() {
                let row = slotIndex / 3
                let col = slotIndex % 3

                // Cada sede tiene 1 sticker con su nombre
                pageSlots.append(StickerSlot(
                    stickerId: startingStickerNumber + slotIndex,
                    position: SlotPosition(row: row, column: col),
                    isSpecialSlot: true,
                    label: venue.city
                ))
            }

            pages.append(AlbumPage(
                pageNumber: 5 + pageIndex,
                section: .venues,
                title: pageIndex == 0 ? "Sedes Mundial 2026" : "Sedes Mundial 2026 (\(pageIndex + 1))",
                subtitle: "Colecciona todas las sedes",
                stickerSlots: pageSlots,
                layoutType: .standard
            ))

            startingStickerNumber += venuesInPage.count
        }

        return pages
    }

    // MARK: - Group Pages
    private static func generateGroupPages(startingStickerNumber: inout Int) -> [AlbumPage] {
        var pages: [AlbumPage] = []

        // 16 grupos (A-P) con 3 equipos cada uno
        let groups = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P"]

        for group in groups {
            let pageSlots = [
                StickerSlot(stickerId: startingStickerNumber, position: SlotPosition(row: 0, column: 0), isSpecialSlot: true), // Header grupo
                StickerSlot(stickerId: startingStickerNumber + 1, position: SlotPosition(row: 1, column: 0)), // Equipo 1
                StickerSlot(stickerId: startingStickerNumber + 2, position: SlotPosition(row: 1, column: 1)), // Equipo 2
                StickerSlot(stickerId: startingStickerNumber + 3, position: SlotPosition(row: 2, column: 0)), // Equipo 3
            ]

            pages.append(AlbumPage(
                pageNumber: 21 + groups.firstIndex(of: group)!,
                section: .groups,
                title: "Grupo \(group)",
                subtitle: "Fase de Grupos",
                stickerSlots: pageSlots
            ))
            startingStickerNumber += 4
        }

        return pages
    }

    // MARK: - Team Pages
    private static func generateTeamPages(startingStickerNumber: inout Int) -> [AlbumPage] {
        var pages: [AlbumPage] = []

        // 48 equipos, cada uno con 1 página
        let teamNames = [
            "México", "USA", "Canadá", "Argentina", "Brasil", "Uruguay",
            "Colombia", "Chile", "Ecuador", "Perú", "Venezuela", "Paraguay",
            "España", "Alemania", "Francia", "Inglaterra", "Italia", "Portugal",
            "Países Bajos", "Bélgica", "Croacia", "Dinamarca", "Suiza", "Austria",
            "Japón", "Corea del Sur", "Australia", "Irán", "Arabia Saudita", "Qatar",
            "Marruecos", "Senegal", "Nigeria", "Túnez", "Camerún", "Ghana",
            "Costa Rica", "Jamaica", "Panamá", "Honduras", "El Salvador", "Trinidad y Tobago",
            "Nueva Zelanda", "Egipto", "Sudáfrica", "Argelia", "Costa de Marfil", "Burkina Faso"
        ]

        for (index, teamName) in teamNames.enumerated() {
            // Cada equipo: 1 escudo + 8 jugadores
            var teamSlots: [StickerSlot] = []

            // Escudo (especial)
            teamSlots.append(StickerSlot(
                stickerId: startingStickerNumber,
                position: SlotPosition(row: 0, column: 1),
                isSpecialSlot: true
            ))

            // 8 jugadores en grid 3x3
            for i in 1...8 {
                let row = (i - 1) / 3 + 1
                let col = (i - 1) % 3
                teamSlots.append(StickerSlot(
                    stickerId: startingStickerNumber + i,
                    position: SlotPosition(row: row, column: col)
                ))
            }

            pages.append(AlbumPage(
                pageNumber: 37 + index,
                section: .teams,
                title: teamName,
                subtitle: "Selección Nacional",
                stickerSlots: teamSlots,
                layoutType: .team
            ))
            startingStickerNumber += 9
        }

        return pages
    }

    // MARK: - Legend Pages
    private static func generateLegendPages(startingStickerNumber: inout Int) -> [AlbumPage] {
        var pages: [AlbumPage] = []

        // 4 páginas de leyendas, 6 por página
        for pageIndex in 0..<4 {
            let pageSlots = (0..<6).map { index in
                StickerSlot(
                    stickerId: startingStickerNumber + index,
                    position: SlotPosition(row: index / 2, column: index % 2),
                    isSpecialSlot: true
                )
            }

            pages.append(AlbumPage(
                pageNumber: 85 + pageIndex,
                section: .legends,
                title: "Leyendas del Fútbol",
                subtitle: "Parte \(pageIndex + 1)",
                stickerSlots: pageSlots
            ))
            startingStickerNumber += 6
        }

        return pages
    }

    // MARK: - Special Pages
    private static func generateSpecialPages(startingStickerNumber: inout Int) -> [AlbumPage] {
        var pages: [AlbumPage] = []

        // Página 1: Balones históricos
        let page1Slots = (0..<4).map { index in
            StickerSlot(
                stickerId: startingStickerNumber + index,
                position: SlotPosition(row: index / 2, column: index % 2),
                isSpecialSlot: true
            )
        }
        pages.append(AlbumPage(
            pageNumber: 89,
            section: .special,
            title: "Balones Oficiales",
            subtitle: "Ediciones Especiales",
            stickerSlots: page1Slots
        ))
        startingStickerNumber += 4

        // Página 2: Momentos históricos
        let page2Slots = (0..<6).map { index in
            StickerSlot(
                stickerId: startingStickerNumber + index,
                position: SlotPosition(row: index / 2, column: index % 2),
                isSpecialSlot: true
            )
        }
        pages.append(AlbumPage(
            pageNumber: 90,
            section: .special,
            title: "Momentos Históricos",
            subtitle: "Goles Legendarios",
            stickerSlots: page2Slots
        ))
        startingStickerNumber += 6

        // Página 3-4: Ultra raras
        for pageIndex in 0..<2 {
            let pageSlots = (0..<4).map { index in
                StickerSlot(
                    stickerId: startingStickerNumber + index,
                    position: SlotPosition(row: index / 2, column: index % 2),
                    isSpecialSlot: true
                )
            }
            pages.append(AlbumPage(
                pageNumber: 91 + pageIndex,
                section: .special,
                title: "Ultra Raras",
                subtitle: "Colección Exclusiva",
                stickerSlots: pageSlots
            ))
            startingStickerNumber += 4
        }

        return pages
    }

    // MARK: - Panini Pages
    private static func generatePaniniPages(startingStickerNumber: inout Int) -> [AlbumPage] {
        var pages: [AlbumPage] = []

        // 8 páginas del álbum Panini especial
        for pageIndex in 0..<8 {
            let stickersPerPage = 9 // Grid 3x3
            let pageSlots = (0..<stickersPerPage).map { index in
                StickerSlot(
                    stickerId: startingStickerNumber + index,
                    position: SlotPosition(row: index / 3, column: index % 3),
                    isSpecialSlot: true
                )
            }

            pages.append(AlbumPage(
                pageNumber: 93 + pageIndex,
                section: .panini,
                title: "Álbum Panini",
                subtitle: "Página \(pageIndex + 1) de 8",
                stickerSlots: pageSlots,
                layoutType: .standard
            ))
            startingStickerNumber += stickersPerPage
        }

        return pages
    }
}

// MARK: - Sticker Collection Manager
class StickerCollectionManager: ObservableObject {
    @Published var collectedStickers: Set<Int> = []
    @Published var duplicateStickers: [Int: Int] = [:] // StickerID : cantidad de duplicados

    init() {
        // Inicializar con algunos stickers de ejemplo para demostración
        // Stickers de introducción
        collectedStickers = Set([1, 2, 4, 5, 8, 10, 12, 15, 18, 20, 23, 25, 28, 30, 33, 35, 38, 40, 42, 45])
    }

    func collectSticker(_ stickerId: Int) {
        if collectedStickers.contains(stickerId) {
            duplicateStickers[stickerId, default: 0] += 1
        } else {
            collectedStickers.insert(stickerId)
        }
    }

    func hasSticker(_ stickerId: Int) -> Bool {
        collectedStickers.contains(stickerId)
    }

    func progress(for section: AlbumSection, totalStickers: Int) -> Double {
        // Calcular progreso por sección (implementar lógica específica)
        return Double(collectedStickers.count) / Double(totalStickers)
    }
}
