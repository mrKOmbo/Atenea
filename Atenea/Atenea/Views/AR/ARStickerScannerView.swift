//
//  ARStickerScannerView.swift
//  Atenea
//
//  Created by Claude on 10/15/25.
//

import SwiftUI
import ARKit
import RealityKit

// MARK: - AR Sticker Scanner View
struct ARStickerScannerView: View {
    @Binding var isPresented: Bool
    @ObservedObject var arService: ARStickerCollectionService
    @ObservedObject var collectionManager: StickerCollectionManager

    @State private var showInstructions = true
    @State private var scanningProgress: Double = 0.0
    @State private var isScanning = false

    var body: some View {
        ZStack {
            // AR View con cámara
            ARViewContainer(
                arService: arService,
                isScanning: $isScanning,
                scanProgress: $scanningProgress
            )
            .ignoresSafeArea()

            // Overlay UI
            VStack {
                // Header
                headerView

                Spacer()

                // Center scanning indicator
                if isScanning {
                    scanningIndicator
                }

                Spacer()

                // Bottom UI
                bottomUIView
            }

            // Instrucciones iniciales
            if showInstructions {
                instructionsOverlay
            }

            // Animación de colección exitosa
            if arService.showCollectionAnimation {
                collectionSuccessOverlay
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                withAnimation {
                    isPresented = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .blur(radius: 10)
                    )
            }

            Spacer()

            if let venue = arService.currentVenue {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(venue.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Text(arService.distanceString(to: venue))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.5))
                        .blur(radius: 10)
                )
            }
        }
        .padding(20)
        .padding(.top, 50)
    }

    // MARK: - Scanning Indicator
    private var scanningIndicator: some View {
        VStack(spacing: 20) {
            // Círculo de escaneo animado
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: scanningProgress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#00D084"), Color(hex: "#C8FF00")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: scanningProgress)

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }

            Text("Escaneando...")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text("\(Int(scanningProgress * 100))%")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.6))
                .blur(radius: 20)
        )
    }

    // MARK: - Bottom UI
    private var bottomUIView: some View {
        VStack(spacing: 16) {
            if let venue = arService.currentVenue {
                // Info de la sede
                VStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 32))
                        .foregroundColor(venue.primaryColor)

                    Text(venue.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text("\(venue.city), \(venue.country)")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.6))
                        .blur(radius: 10)
                )

                // Botón de escanear
                if arService.canCollectSticker {
                    Button(action: {
                        startScanning()
                    }) {
                        HStack(spacing: 12) {
                            if isScanning {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 20))
                            }

                            Text(isScanning ? "Escaneando..." : "Coleccionar Stickers")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#00D084"),
                                    Color(hex: "#00A067")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .disabled(isScanning)
                    .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "location.slash")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)

                        Text("Acércate más a la sede")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Debes estar a menos de 100m")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.6))
                            .blur(radius: 10)
                    )
                }
            } else {
                // No hay sedes cerca
                VStack(spacing: 12) {
                    Image(systemName: "map")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.6))

                    Text("No hay sedes cerca")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Visita una sede del Mundial 2026")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.6))
                        .blur(radius: 10)
                )
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Instructions Overlay
    private var instructionsOverlay: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Image(systemName: "camera.metering.center.weighted")
                    .font(.system(size: 80))
                    .foregroundColor(Color(hex: "#00D084"))

                Text("Colecciona Stickers con AR")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                VStack(spacing: 20) {
                    ARInstructionRow(
                        icon: "location.fill",
                        text: "Visita una sede del Mundial 2026"
                    )

                    ARInstructionRow(
                        icon: "camera.fill",
                        text: "Abre el escáner AR cuando estés cerca"
                    )

                    ARInstructionRow(
                        icon: "photo.on.rectangle.angled",
                        text: "Colecciona 1 sticker por cada sede"
                    )
                }
                .padding(.horizontal, 30)

                Button(action: {
                    withAnimation {
                        showInstructions = false
                    }
                }) {
                    Text("Comenzar")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#00D084"),
                                    Color(hex: "#00A067")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
        }
    }

    // MARK: - Collection Success Overlay
    private var collectionSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // Animación de éxito
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#00D084").opacity(0.3),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .scaleEffect(arService.showCollectionAnimation ? 1.5 : 0.5)
                        .opacity(arService.showCollectionAnimation ? 0 : 1)
                        .animation(.easeOut(duration: 1.5), value: arService.showCollectionAnimation)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(Color(hex: "#00D084"))
                        .scaleEffect(arService.showCollectionAnimation ? 1 : 0.3)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: arService.showCollectionAnimation)
                }

                VStack(spacing: 12) {
                    Text("¡Stickers Coleccionados!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    if let venue = arService.currentVenue {
                        Text(venue.name)
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Text("+1 Sticker")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "#C8FF00"))
                }
            }
        }
    }

    // MARK: - Start Scanning
    private func startScanning() {
        guard let venue = arService.currentVenue else { return }

        isScanning = true
        scanningProgress = 0.0

        // Simular progreso de escaneo
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if scanningProgress < 1.0 {
                scanningProgress += 0.02
            } else {
                timer.invalidate()

                // Coleccionar stickers
                arService.collectStickerForVenue(venue, collectionManager: collectionManager)

                // Resetear estado
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isScanning = false
                    scanningProgress = 0.0
                }
            }
        }
    }
}

// MARK: - AR Instruction Row
struct ARInstructionRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "#00D084"))
                .frame(width: 40)

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)

            Spacer()
        }
    }
}

// MARK: - AR View Container (UIViewRepresentable)
struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var arService: ARStickerCollectionService
    @Binding var isScanning: Bool
    @Binding var scanProgress: Double

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configurar sesión AR
        let configuration = arService.createARConfiguration()
        arView.session.run(configuration)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Actualizar vista si es necesario
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: ()) {
        uiView.session.pause()
    }
}

#Preview {
    ARStickerScannerView(
        isPresented: .constant(true),
        arService: ARStickerCollectionService.shared,
        collectionManager: StickerCollectionManager()
    )
}
