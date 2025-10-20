//
//  NavigationArrowView.swift
//  AteneaWatch Watch App
//
//  Created by Claude Code
//

import SwiftUI

struct NavigationArrowView: View {
    @StateObject private var viewModel = NavigationWatchViewModel()
    @ObservedObject var connectivityManager = WatchConnectivityManager.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isNavigating {
                VStack(spacing: 20) {
                    // Distancia restante
                    Text(viewModel.distanceText)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    // Flecha principal
                    ArrowShape()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.blue]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 80, height: 120)
                        .shadow(color: .green.opacity(0.6), radius: 10, x: 0, y: 0)
                        .rotationEffect(.degrees(viewModel.arrowRotation))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.arrowRotation)

                    // Destino
                    Text(connectivityManager.destinationName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }
            } else {
                // Mostrar mapa cuando no hay navegación activa
                MapWatchView()
            }
        }
    }
}

struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let cornerRadius: CGFloat = 8 // Radio para las esquinas redondeadas

        // Punta de la flecha (mantener puntiaguda)
        path.move(to: CGPoint(x: width / 2, y: 0))

        // Lado derecho de la punta
        path.addLine(to: CGPoint(x: width, y: height * 0.35))

        // Esquina redondeada superior derecha (transición a cuerpo)
        path.addQuadCurve(
            to: CGPoint(x: width * 0.65, y: height * 0.35 + cornerRadius),
            control: CGPoint(x: width * 0.65, y: height * 0.35)
        )

        // Borde derecho del cuerpo
        path.addLine(to: CGPoint(x: width * 0.65, y: height - cornerRadius))

        // Esquina redondeada inferior derecha
        path.addQuadCurve(
            to: CGPoint(x: width * 0.65 - cornerRadius, y: height),
            control: CGPoint(x: width * 0.65, y: height)
        )

        // Base inferior
        path.addLine(to: CGPoint(x: width * 0.35 + cornerRadius, y: height))

        // Esquina redondeada inferior izquierda
        path.addQuadCurve(
            to: CGPoint(x: width * 0.35, y: height - cornerRadius),
            control: CGPoint(x: width * 0.35, y: height)
        )

        // Borde izquierdo del cuerpo
        path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.35 + cornerRadius))

        // Esquina redondeada superior izquierda (transición a cuerpo)
        path.addQuadCurve(
            to: CGPoint(x: 0, y: height * 0.35),
            control: CGPoint(x: width * 0.35, y: height * 0.35)
        )

        // Lado izquierdo de la punta
        path.addLine(to: CGPoint(x: width / 2, y: 0))

        path.closeSubpath()

        return path
    }
}

#Preview {
    NavigationArrowView()
}
