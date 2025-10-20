//
//  UserLocationIndicator.swift
//  Atenea
//
//  Created by Claude on 10/13/25.
//

import SwiftUI
import CoreLocation

struct UserLocationIndicator: View {
    let heading: CLHeading?
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Círculo exterior con pulso animado
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.blue.opacity(0.0)
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 35
                    )
                )
                .frame(width: 70, height: 70)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0.0 : 1.0)
                .animation(
                    .easeOut(duration: 2.0)
                    .repeatForever(autoreverses: false),
                    value: isPulsing
                )
                .onAppear {
                    isPulsing = true
                }

            // Círculo medio semi-transparente
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .blur(radius: 2)

            // Indicador de dirección (cono de luz) - DEBAJO del punto
            if let heading = heading {
                DirectionBeam()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.7),
                                Color.blue.opacity(0.3),
                                Color.blue.opacity(0.0)
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 50, height: 65)
                    .shadow(color: Color.blue.opacity(0.5), radius: 8, x: 0, y: 0)
                    .offset(y: -42)
                    .rotationEffect(.degrees(-heading.trueHeading), anchor: .bottom)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: heading.trueHeading)
            }

            // Punto central principal (encima de todo)
            ZStack {
                // Sombra del punto
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 26, height: 26)
                    .blur(radius: 4)
                    .offset(y: 2)

                // Círculo azul con gradiente
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.4, green: 0.7, blue: 1.0),
                                Color.blue
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 13
                        )
                    )
                    .frame(width: 26, height: 26)

                // Borde blanco
                Circle()
                    .stroke(Color.white, lineWidth: 3.5)
                    .frame(width: 26, height: 26)

                // Brillo interior
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.0)
                            ]),
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 0,
                            endRadius: 13
                        )
                    )
                    .frame(width: 26, height: 26)
            }
        }
    }
}

// Forma personalizada para el haz de dirección (cono más bonito)
struct DirectionBeam: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Crear un cono más ancho y suave que apunta hacia arriba
        let centerX = width * 0.5
        let baseY = height
        let tipY: CGFloat = 0

        // Base del cono (más ancha)
        path.move(to: CGPoint(x: centerX, y: baseY))

        // Lado izquierdo con curva suave
        path.addQuadCurve(
            to: CGPoint(x: width * 0.15, y: height * 0.5),
            control: CGPoint(x: width * 0.25, y: height * 0.75)
        )

        // Subir hacia la punta (lado izquierdo)
        path.addQuadCurve(
            to: CGPoint(x: centerX, y: tipY),
            control: CGPoint(x: width * 0.25, y: height * 0.15)
        )

        // Bajar desde la punta (lado derecho)
        path.addQuadCurve(
            to: CGPoint(x: width * 0.85, y: height * 0.5),
            control: CGPoint(x: width * 0.75, y: height * 0.15)
        )

        // Lado derecho con curva suave
        path.addQuadCurve(
            to: CGPoint(x: centerX, y: baseY),
            control: CGPoint(x: width * 0.75, y: height * 0.75)
        )

        path.closeSubpath()

        return path
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        UserLocationIndicator(
            heading: CLHeading()
        )
    }
}
