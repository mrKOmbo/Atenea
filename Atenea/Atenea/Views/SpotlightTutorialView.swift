//
//  SpotlightTutorialView.swift
//  Atenea
//
//  Tutorial with spotlight for app features
//

import SwiftUI

// MARK: - Tutorial Step Model
struct TutorialStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let spotlightPosition: CGPoint
    let spotlightRadius: CGFloat
    let textPosition: TextPosition

    enum TextPosition {
        case top, bottom, left, right
    }
}

// MARK: - Spotlight Tutorial View
struct SpotlightTutorialView: View {
    @Binding var showTutorial: Bool
    @State private var currentStep = 0
    @State private var opacity: Double = 0

    let steps: [TutorialStep]

    var body: some View {
        ZStack {
            // Overlay oscuro con agujero circular
            SpotlightOverlay(
                spotlightPosition: steps[currentStep].spotlightPosition,
                spotlightRadius: steps[currentStep].spotlightRadius
            )
            .opacity(opacity)

            // Contenido del tutorial
            VStack {
                if steps[currentStep].textPosition == .top {
                    tutorialContent
                        .padding(.top, 100)
                    Spacer()
                } else if steps[currentStep].textPosition == .bottom {
                    Spacer()
                    tutorialContent
                        .padding(.bottom, 120)
                }
            }
            .opacity(opacity)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
        }
    }

    // MARK: - Tutorial Content
    private var tutorialContent: some View {
        VStack(spacing: 20) {
            // Título
            Text(steps[currentStep].title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Descripción
            Text(steps[currentStep].description)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Indicadores de paso
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentStep ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 10)

            // Botones
            HStack(spacing: 16) {
                // Botón Saltar
                if currentStep < steps.count - 1 {
                    Button(action: {
                        skipTutorial()
                    }) {
                        Text(LocalizedString("action.skip"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                            )
                    }
                }

                // Botón Siguiente/Comenzar
                Button(action: {
                    nextStep()
                }) {
                    Text(currentStep < steps.count - 1 ? LocalizedString("action.next") : LocalizedString("action.start"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "#1a1a1a"))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#FFD700"),
                                    Color(hex: "#FFC72C")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color(hex: "#FFD700").opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.top, 10)
        }
    }

    // MARK: - Actions
    private func nextStep() {
        if currentStep < steps.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentStep += 1
                withAnimation(.easeInOut(duration: 0.3)) {
                    opacity = 1
                }
            }
        } else {
            finishTutorial()
        }
    }

    private func skipTutorial() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showTutorial = false
        }
    }

    private func finishTutorial() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showTutorial = false
        }
    }
}

// MARK: - Spotlight Overlay
struct SpotlightOverlay: View {
    let spotlightPosition: CGPoint
    let spotlightRadius: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fondo oscuro completo
                Color.black.opacity(0.85)
                    .ignoresSafeArea()

                // Agujero circular (spotlight)
                Circle()
                    .frame(width: spotlightRadius * 2, height: spotlightRadius * 2)
                    .position(spotlightPosition)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
        }
    }
}

// MARK: - Tutorial Steps Factory
extension SpotlightTutorialView {
    static func createDefaultSteps(screenSize: CGSize) -> [TutorialStep] {
        // Cálculos precisos para posiciones
        let menuButtonX = screenSize.width - 16 - 22 // padding + mitad del botón (44/2)
        let menuButtonY: CGFloat = 50 + 22 // padding top + mitad del botón

        let tabBarY = screenSize.height - 70 // Más abajo para abarcar mejor el tab bar
        let tab1X = screenSize.width / 6 // Primera tercera parte
        let tab2X = screenSize.width / 2 // Centro
        let tab3X = (5 * screenSize.width) / 6 // Última tercera parte

        let categoryButtonY: CGFloat = 180 // Debajo del header de búsqueda
        let categoryButtonX: CGFloat = 100 // Aproximado primer botón visible

        return [
            TutorialStep(
                title: LocalizedString("tutorial.welcome"),
                description: LocalizedString("tutorial.welcomeDesc"),
                spotlightPosition: CGPoint(x: screenSize.width / 2, y: screenSize.height / 2.5),
                spotlightRadius: 180,
                textPosition: .bottom
            ),
            TutorialStep(
                title: LocalizedString("tutorial.menu"),
                description: LocalizedString("tutorial.menuDesc"),
                spotlightPosition: CGPoint(x: menuButtonX, y: menuButtonY),
                spotlightRadius: 70,
                textPosition: .bottom
            ),
            TutorialStep(
                title: LocalizedString("tutorial.search"),
                description: LocalizedString("tutorial.searchDesc"),
                spotlightPosition: CGPoint(x: screenSize.width / 2, y: categoryButtonY),
                spotlightRadius: 120,
                textPosition: .bottom
            ),
            TutorialStep(
                title: LocalizedString("tutorial.community"),
                description: LocalizedString("tutorial.communityDesc"),
                spotlightPosition: CGPoint(x: tab2X, y: tabBarY),
                spotlightRadius: 80,
                textPosition: .top
            ),
            TutorialStep(
                title: LocalizedString("tutorial.album"),
                description: LocalizedString("tutorial.albumDesc"),
                spotlightPosition: CGPoint(x: tab3X, y: tabBarY),
                spotlightRadius: 80,
                textPosition: .top
            )
        ]
    }
}

// MARK: - Preview
#Preview {
    GeometryReader { geometry in
        SpotlightTutorialView(
            showTutorial: .constant(true),
            steps: SpotlightTutorialView.createDefaultSteps(screenSize: geometry.size)
        )
    }
}
