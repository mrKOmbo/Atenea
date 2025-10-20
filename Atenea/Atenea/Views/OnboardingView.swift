//
//  OnboardingView.swift
//  Atenea
//
//  Onboarding screen for Mundial 2026
//

import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool

    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var mountainOffset: CGFloat = 100

    var body: some View {
        ZStack {
            // Fondo con gradiente usando colores del splash screen
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#0072CE"), // Azul real - Kansas City
                    Color(hex: "#00A651"), // Verde brillante - Guadalajara
                    Color(hex: "#0D47A1"), // Azul índigo - Atlanta
                    Color(hex: "#34A853"), // Verde esmeralda - Ciudad de México
                    Color(hex: "#8BC53F")  // Verde lima - Seattle
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Nubes decorativas en la parte superior
            VStack {
                HStack(spacing: 20) {
                    CloudShape()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 120, height: 40)
                        .offset(x: -50, y: 20)

                    CloudShape()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 150, height: 50)
                        .offset(x: 100, y: 40)
                }
                Spacer()
            }

            // Montañas en capas (de atrás hacia adelante)
            GeometryReader { geometry in
                ZStack {
                    // Montaña trasera (más clara) - Azul claro del splash
                    MountainShape1()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#00A9E0").opacity(0.5), // Azul cian
                                    Color(hex: "#0072CE").opacity(0.6)  // Azul real
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: geometry.size.height * 0.6)
                        .offset(y: mountainOffset + geometry.size.height * 0.35)

                    // Montaña media - Verdes del splash
                    MountainShape2()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#00A651").opacity(0.7), // Verde brillante
                                    Color(hex: "#34A853").opacity(0.8)  // Verde esmeralda
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: geometry.size.height * 0.65)
                        .offset(y: mountainOffset + geometry.size.height * 0.38)

                    // Montaña delantera - Colores cálidos del splash
                    MountainShape3()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#FFC72C").opacity(0.7), // Amarillo solar
                                    Color(hex: "#F58220").opacity(0.8)  // Naranja encendido
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: geometry.size.height * 0.55)
                        .offset(y: mountainOffset + geometry.size.height * 0.48)

                    // Árboles en primer plano - Tonos oscuros
                    HStack(spacing: 40) {
                        TreeShape()
                            .fill(Color(hex: "#0A2D6C").opacity(0.85)) // Azul marino profundo
                            .frame(width: 30, height: 80)
                            .offset(x: -150, y: mountainOffset + geometry.size.height * 0.6)

                        TreeShape()
                            .fill(Color(hex: "#00573D").opacity(0.75)) // Verde bosque
                            .frame(width: 25, height: 70)
                            .offset(x: 150, y: mountainOffset + geometry.size.height * 0.65)
                    }
                }
            }

            // Contenido principal
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 100)

                // Logo/Título
                VStack(spacing: 12) {
                    Text(LocalizedString("onboarding.title"))
                        .font(.custom("FIFA Welcome", size: 64))
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color(hex: "#F0F0F0")
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        .opacity(titleOpacity)

                    Text(LocalizedString("onboarding.subtitle"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .opacity(subtitleOpacity)
                }
                .padding(.horizontal, 40)

                Spacer()

                // Botón principal
                VStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showOnboarding = false
                        }
                    }) {
                        Text(LocalizedString("action.start"))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "#1a1a1a"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#FFD700"), // Dorado Copa del Mundo
                                        Color(hex: "#FFC72C")  // Amarillo brillante
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color(hex: "#FFD700").opacity(0.5), radius: 12, x: 0, y: 8)
                    }
                    .opacity(buttonOpacity)

                    // Características principales
                    HStack(spacing: 30) {
                        FeatureItem(icon: "map.fill", text: LocalizedString("onboarding.venues"))
                        FeatureItem(icon: "camera.fill", text: LocalizedString("onboarding.scanner"))
                        FeatureItem(icon: "square.grid.3x3.fill", text: LocalizedString("onboarding.album"))
                    }
                    .opacity(buttonOpacity)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Animación de entrada
            withAnimation(.easeOut(duration: 1.0)) {
                mountainOffset = 0
            }

            withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                titleOpacity = 1
            }

            withAnimation(.easeOut(duration: 0.8).delay(0.7)) {
                subtitleOpacity = 1
            }

            withAnimation(.easeOut(duration: 0.8).delay(0.9)) {
                buttonOpacity = 1
            }
        }
    }
}

// MARK: - Feature Item
struct FeatureItem: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)

            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Mountain Shapes
struct MountainShape1: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height * 0.4))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.3, y: rect.height * 0.2),
            control: CGPoint(x: rect.width * 0.15, y: rect.height * 0.25)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.6, y: rect.height * 0.35),
            control: CGPoint(x: rect.width * 0.45, y: rect.height * 0.1)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.5),
            control: CGPoint(x: rect.width * 0.8, y: rect.height * 0.4)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()

        return path
    }
}

struct MountainShape2: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height * 0.6))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.25, y: rect.height * 0.3),
            control: CGPoint(x: rect.width * 0.1, y: rect.height * 0.4)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.5, y: rect.height * 0.15),
            control: CGPoint(x: rect.width * 0.35, y: rect.height * 0.15)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.75, y: rect.height * 0.4),
            control: CGPoint(x: rect.width * 0.65, y: rect.height * 0.2)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.55),
            control: CGPoint(x: rect.width * 0.9, y: rect.height * 0.45)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()

        return path
    }
}

struct MountainShape3: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height * 0.5))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.4, y: rect.height * 0.25),
            control: CGPoint(x: rect.width * 0.2, y: rect.height * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.7, y: rect.height * 0.45),
            control: CGPoint(x: rect.width * 0.55, y: rect.height * 0.15)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.6),
            control: CGPoint(x: rect.width * 0.85, y: rect.height * 0.5)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Cloud Shape
struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.addArc(
            center: CGPoint(x: rect.width * 0.25, y: rect.height * 0.5),
            radius: rect.height * 0.4,
            startAngle: .degrees(0),
            endAngle: .degrees(360),
            clockwise: false
        )

        path.addArc(
            center: CGPoint(x: rect.width * 0.5, y: rect.height * 0.35),
            radius: rect.height * 0.5,
            startAngle: .degrees(0),
            endAngle: .degrees(360),
            clockwise: false
        )

        path.addArc(
            center: CGPoint(x: rect.width * 0.75, y: rect.height * 0.5),
            radius: rect.height * 0.45,
            startAngle: .degrees(0),
            endAngle: .degrees(360),
            clockwise: false
        )

        return path
    }
}

// MARK: - Tree Shape
struct TreeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Tronco
        path.addRect(CGRect(
            x: rect.width * 0.4,
            y: rect.height * 0.6,
            width: rect.width * 0.2,
            height: rect.height * 0.4
        ))

        // Copa del árbol (triángulo)
        path.move(to: CGPoint(x: rect.width * 0.5, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.1, y: rect.height * 0.7))
        path.addLine(to: CGPoint(x: rect.width * 0.9, y: rect.height * 0.7))
        path.closeSubpath()

        return path
    }
}
