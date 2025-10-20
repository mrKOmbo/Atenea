//
//  VenueDetailView.swift
//  Atenea
//
//  Created by Claude on 10/12/25.
//

import SwiftUI
import MapKit

struct VenueDetailView: View {
    let venue: WorldCupVenue
    @Binding var isPresented: Bool
    @State private var funFactsExpanded = false
    @State private var matchesExpanded = true // Partidos expandidos por defecto
    @State private var dragOffset: CGFloat = 0
    var onDismiss: (() -> Void)?

    // Función para abrir en Apple Maps
    private func openInMaps() {
        let coordinate = venue.coordinate
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = venue.name

        // Abrir con direcciones en modo conducción
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Fondo semi-transparente para cerrar al tocar fuera
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                            onDismiss?()
                        }
                    }
                    .zIndex(0) // Fondo en el nivel más bajo

                // Panel compacto en la parte inferior
                VStack(spacing: 0) {
                    // Marcador de sede conectado al panel (más pequeño)
                    VStack(spacing: 0) {
                        // Pin/Marcador visual
                        ZStack {
                            // Círculo con el color de la sede
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [venue.primaryColor, venue.secondaryColor]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                                .shadow(color: venue.primaryColor.opacity(0.6), radius: 8, x: 0, y: 2)

                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 32, height: 32)

                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                        .offset(y: 8)

                        // Línea conectora
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        venue.primaryColor.opacity(0.6),
                                        venue.primaryColor.opacity(0.3)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 2, height: 8)
                    }
                    .zIndex(10)

                    // Contenido del panel
                    VStack(spacing: 0) {
                        // Header compacto con background completo
                        ZStack {
                            // Background que se expande completamente
                            venue.gradient
                                .overlay(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.black.opacity(0.25),
                                            Color.clear
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            // Contenido del header
                            VStack(spacing: 6) {
                                // Barra de arrastre con gesture
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 40, height: 4)
                                    .padding(.top, 6)
                                    .padding(.bottom, 8)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                // Solo permitir arrastre hacia abajo
                                                if value.translation.height > 0 {
                                                    dragOffset = value.translation.height
                                                }
                                            }
                                            .onEnded { value in
                                                // Si se arrastró más de 100 puntos, cerrar el modal
                                                if value.translation.height > 100 {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                        isPresented = false
                                                        onDismiss?()
                                                    }
                                                    dragOffset = 0
                                                } else {
                                                    // Si no, regresar a la posición original
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                        dragOffset = 0
                                                    }
                                                }
                                            }
                                    )

                                // Nombre y ubicación
                                VStack(spacing: 3) {
                                    Text(venue.name)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)

                                    Text("\(venue.city), \(venue.country)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white.opacity(0.85))

                                    // Capacidad e Inauguración compactos
                                    HStack(spacing: 10) {
                                        HStack(spacing: 3) {
                                            Image(systemName: "person.3.fill")
                                                .font(.system(size: 9))
                                            Text(venue.capacity)
                                                .font(.system(size: 10, weight: .medium))
                                        }

                                        HStack(spacing: 3) {
                                            Image(systemName: "calendar")
                                                .font(.system(size: 9))
                                            Text(venue.inauguration)
                                                .font(.system(size: 10, weight: .medium))
                                        }
                                    }
                                    .foregroundColor(.white.opacity(0.7))

                                    // Botón para abrir en Apple Maps
                                    Button(action: openInMaps) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "location.fill")
                                                .font(.system(size: 11))
                                            Text("Cómo llegar")
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            LinearGradient(
                                                colors: [venue.primaryColor, venue.secondaryColor],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(12)
                                        .shadow(color: venue.primaryColor.opacity(0.3), radius: 4, x: 0, y: 2)
                                    }
                                    .padding(.top, 6)
                                }
                                .padding(.horizontal, 14)
                                .padding(.bottom, 8)
                            }
                        }

                        // Contenido scrolleable
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 12) {
                                // Sección de Partidos (expandible)
                                VStack(spacing: 0) {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            matchesExpanded.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "soccerball.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(venue.primaryColor)

                                            Text("PARTIDOS")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white.opacity(0.7))

                                            Text("\(venue.matches.count)")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(venue.primaryColor)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(
                                                    Capsule()
                                                        .fill(venue.primaryColor.opacity(0.2))
                                                )

                                            Spacer()

                                            Image(systemName: matchesExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(venue.primaryColor)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.05))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(venue.primaryColor.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                        .padding(.horizontal, 12)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    if matchesExpanded {
                                        VStack(spacing: 6) {
                                            ForEach(Array(venue.matches.prefix(3).enumerated()), id: \.element.id) { index, match in
                                                CompactMatchCard(match: match, color: venue.primaryColor, index: index + 1)
                                            }
                                            if venue.matches.count > 3 {
                                                Text("+\(venue.matches.count - 3) partidos más")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.5))
                                                    .padding(.vertical, 4)
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.top, 6)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }

                                // Sección de Datos Curiosos (expandible)
                                VStack(spacing: 0) {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            funFactsExpanded.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "lightbulb.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.yellow)

                                            Text("DATOS CURIOSOS")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white.opacity(0.7))

                                            Text("\(venue.funFacts.count)")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(venue.primaryColor)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(
                                                    Capsule()
                                                        .fill(venue.primaryColor.opacity(0.2))
                                                )

                                            Spacer()

                                            Image(systemName: funFactsExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(venue.primaryColor)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.05))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(venue.primaryColor.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                        .padding(.horizontal, 12)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    if funFactsExpanded {
                                        VStack(spacing: 6) {
                                            ForEach(Array(venue.funFacts.prefix(2).enumerated()), id: \.offset) { index, fact in
                                                CompactFunFactCard(fact: fact, index: index + 1, color: venue.primaryColor)
                                            }
                                            if venue.funFacts.count > 2 {
                                                Text("+\(venue.funFacts.count - 2) datos más")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.5))
                                                    .padding(.vertical, 4)
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.top, 6)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }

                                Color.clear.frame(height: 4)
                            }
                            .padding(.top, 12)
                        }
                        .frame(maxHeight: 200)

                        // Botón de cerrar compacto
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isPresented = false
                                onDismiss?()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                Text("Cerrar")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(venue.primaryColor)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.05))
                    }
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)

                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.15),
                                            Color.white.opacity(0.08)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: venue.primaryColor.opacity(0.3), radius: 20, x: 0, y: -10)
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: -5)
                }
                .frame(maxWidth: 340, maxHeight: 500)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .offset(y: dragOffset)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1) // Panel por encima del fondo para capturar gestos
            }
        }
    }
}

// Tarjeta de partido mini (ultra compacta)
struct MiniMatchCard: View {
    let match: WorldCupMatch
    let color: Color
    let index: Int

    var body: some View {
        HStack(spacing: 6) {
            // Número de partido
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)
                    .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)

                Text("\(index)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(match.stage)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(color)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(color.opacity(0.2)))

                Text(match.date)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

// Tarjeta de partido compacta
struct CompactMatchCard: View {
    let match: WorldCupMatch
    let color: Color
    let index: Int

    var body: some View {
        HStack(spacing: 8) {
            // Número de partido
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .shadow(color: color.opacity(0.4), radius: 3, x: 0, y: 2)

                Text("\(index)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(match.stage)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(color.opacity(0.2)))

                Text(match.date)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))

                if match.time != "Por definir" {
                    Text(match.time)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                if match.teams != "Por definir" {
                    Text(match.teams)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// Tarjeta de dato curioso mini (ultra compacta)
struct MiniFunFactCard: View {
    let fact: String
    let index: Int
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 5) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 16, height: 16)

                Text("\(index)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(color)
            }

            Text(fact)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
}

// Tarjeta de dato curioso compacta
struct CompactFunFactCard: View {
    let fact: String
    let index: Int
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.25))
                    .frame(width: 24, height: 24)

                Text("\(index)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(color)
            }
            .padding(.top, 2)

            Text(fact)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        // Fondo de mapa simulado
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.4),
                Color.green.opacity(0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VenueDetailView(
            venue: WorldCupVenue.allVenues[1], // Estadio Azteca
            isPresented: .constant(true)
        )
    }
}
