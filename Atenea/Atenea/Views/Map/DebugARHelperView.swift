//
//  DebugARHelperView.swift
//  Atenea
//
//  Created by Claude on 10/15/25.
//

import SwiftUI

// MARK: - Debug Helper para Testing de AR
struct DebugARHelperView: View {
    @ObservedObject var arService: ARStickerCollectionService
    @ObservedObject var collectionManager: StickerCollectionManager
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("🧪 Debug AR")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Text("Simular estar cerca de una sede")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))

                Divider()
                    .background(Color.white.opacity(0.3))
                    .padding(.horizontal, 20)

                // Lista de sedes
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(WorldCupVenue.allVenues) { venue in
                            DebugVenueButton(
                                venue: venue,
                                arService: arService,
                                collectionManager: collectionManager
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Debug Venue Button
struct DebugVenueButton: View {
    let venue: WorldCupVenue
    @ObservedObject var arService: ARStickerCollectionService
    @ObservedObject var collectionManager: StickerCollectionManager

    var body: some View {
        Button(action: {
            simulateCollection()
        }) {
            HStack(spacing: 16) {
                // Icono de la sede
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [venue.primaryColor, venue.secondaryColor]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    )

                // Info de la sede
                VStack(alignment: .leading, spacing: 4) {
                    Text(venue.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text("\(venue.city), \(venue.country)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Indicador de colección
                if hasCollectedStickers(for: venue) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#00D084"))
                } else {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(venue.primaryColor.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func simulateCollection() {
        #if DEBUG
        // Simular estar cerca de la sede
        arService.simulateNearVenue(venue)

        // Esperar un poco para que se actualice la UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Simular colección
            arService.simulateCollection(for: venue, collectionManager: collectionManager)
        }
        #endif
    }

    private func hasCollectedStickers(for venue: WorldCupVenue) -> Bool {
        let venueIndex = WorldCupVenue.allVenues.firstIndex(where: { $0.id == venue.id }) ?? 0
        let stickerId = 14 + venueIndex

        // Verificar si el sticker de esta sede está coleccionado
        return collectionManager.hasSticker(stickerId)
    }
}

#Preview {
    DebugARHelperView(
        arService: ARStickerCollectionService.shared,
        collectionManager: StickerCollectionManager(),
        isPresented: .constant(true)
    )
}
