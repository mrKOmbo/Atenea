//
//  ClaudeMessageView.swift
//  Atenea
//
//  Created by Claude on 10/15/25.
//

import SwiftUI
import MapKit

// MARK: - Vista de Mensaje de Claude con Lugares Clickeables

struct ClaudeMessageView: View {
    let message: String
    let onPlaceSelected: (PlaceLocation) -> Void

    @State private var places: [PlaceLocation] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Texto del mensaje (sin las coordenadas)
            Text(ClaudeResponseParser.cleanResponse(text: message))
                .font(.system(size: 16))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            // Lugares como botones clickeables
            if !places.isEmpty {
                VStack(spacing: 8) {
                    ForEach(places) { place in
                        PlaceButton(place: place) {
                            onPlaceSelected(place)
                        }
                    }
                }
            }
        }
        .onAppear {
            places = ClaudeResponseParser.parsePlaces(from: message)
        }
    }
}

// MARK: - Botón de Lugar

struct PlaceButton: View {
    let place: PlaceLocation
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // Feedback háptico
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                action()
            }
        }) {
            HStack(spacing: 12) {
                // Ícono de pin
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(0.8),
                                    Color.orange.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Información del lugar
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    if let description = place.description {
                        Text(description)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }

                    // Coordenadas pequeñas
                    Text("📍 \(String(format: "%.4f", place.latitude)), \(String(format: "%.4f", place.longitude))")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isPressed ? 0.15 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.red.opacity(0.3),
                                Color.orange.opacity(0.2)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            )
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

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            ClaudeMessageView(
                message: """
                Te recomiendo estos lugares:

                🌮 [LUGAR: Tacos El Güero | LAT: 19.4326 | LON: -99.1332] - Los mejores tacos al pastor

                🏛️ [LUGAR: Museo Frida Kahlo | LAT: 19.3551 | LON: -99.1620] - Casa Azul imperdible
                """,
                onPlaceSelected: { place in
                    print("Lugar seleccionado: \(place.name)")
                }
            )
            .padding()
        }
    }
}
