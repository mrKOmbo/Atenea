//  SplashScreenView.swift
//  Atenea
//
//  Splash screen for Mundial 2026 app
//

import SwiftUI

struct NumberLayer: Identifiable {
    let id = UUID()
    var scale: CGFloat
    var color: Color
}

struct SplashScreenView: View {
    @Binding var showSplash: Bool

    @State private var layers: [NumberLayer] = [NumberLayer(scale: 1, color: .white)]
    @State private var currentColorIndex = 0
    @State private var cupScale: CGFloat = 0.7
    @State private var fifaScale: CGFloat = 0.7
    @State private var fifaOffset: CGFloat = -75
    @State private var isContracting = false
    @State private var circleScale: CGFloat = 0

    let colors: [Color] = [
        .white,
        // Verdes Vibrantes
        Color(hex: "#00A651"), // Verde brillante - Guadalajara
        Color(hex: "#34A853"), // Verde esmeralda - Ciudad de México
        Color(hex: "#8BC53F"), // Verde lima - Seattle
        Color(hex: "#00573D"), // Verde bosque - Vancouver
        // Azules Profundos y Eléctricos
        Color(hex: "#0072CE"), // Azul real - Kansas City
        Color(hex: "#00A9E0"), // Azul cian - Toronto
        Color(hex: "#0A2D6C"), // Azul marino profundo - Nueva York/Nueva Jersey
        Color(hex: "#0D47A1"), // Azul índigo - Atlanta
        // Rojos y Naranjas Energéticos
        Color(hex: "#EF4135"), // Rojo pasión - Monterrey
        Color(hex: "#E41E26"), // Rojo carmesí - Toronto
        Color(hex: "#F58220"), // Naranja encendido - Miami
        Color(hex: "#FF5A00"), // Naranja neón - Houston
        // Amarillos y Dorados Solares
        Color(hex: "#FFC72C"), // Amarillo solar - Los Ángeles
        Color(hex: "#FDB913"), // Amarillo dorado - Filadelfia
        Color(hex: "#FFEB3B"), // Amarillo limón - Monterrey
        Color(hex: "#EAAA00"), // Dorado trofeo - Boston
        // Púrpuras y Rosas Atrevidos
        Color(hex: "#A14593"), // Púrpura vibrante - Ciudad de México
        Color(hex: "#662D8C"), // Violeta - Dallas
        Color(hex: "#EC008C"), // Rosa magenta - Vancouver
        Color(hex: "#FF007F")  // Rosa neón - Miami
    ]

    var body: some View {
        ZStack {
            // Fondo negro
            Color.black
                .ignoresSafeArea()

            // Todas las capas de números expandiéndose/contrayéndose
            ForEach(layers) { layer in
                VStack(spacing: -75) {
                    Text("2")
                    Text("6")
                }
                .font(.custom("FIFA 26", size: 120))
                .foregroundStyle(layer.color)
                .scaleEffect(isContracting ? 0 : layer.scale)
                .offset(y: -45)
                .opacity(isContracting ? 0 : 1)
            }

            // Contenedor con la copa y texto FIFA siempre al frente
            VStack(spacing: 15) {
                ZStack {
                    VStack {
                        // Imagen de la copa
                        Image("Copa")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 350)
                            .offset(x:-5)
                            .scaleEffect(isContracting ? 0 : cupScale)
                            .opacity(isContracting ? 0 : 1)
                        // Texto "FIFA" separado
                        Text("FIFA")
                            .font(.custom("FIFA Welcome", size: 60))
                            .fontWeight(.black)
                            .foregroundStyle(.black)
                            .kerning(8)
                            .bold()
                            .scaleEffect(isContracting ? 0 : fifaScale)
                            .offset(x:7, y: fifaOffset)
                            .opacity(isContracting ? 0 : 1)
                    }
                }
            }

            // Círculo blanco que se expande (encima del splash)
            Circle()
                .fill(Color.white)
                .scaleEffect(circleScale)
                .ignoresSafeArea()
        }
        .onAppear {
            // Esperar 1.5 segundos antes de iniciar la animación
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                startAnimation()
                // Animar copa y texto FIFA para que crezcan y el texto se baje
                withAnimation(.easeOut(duration: 0.8)) {
                    cupScale = 1.0
                    fifaScale = 1.0
                    fifaOffset = 0
                }
            }
        }
    }

    func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.18, repeats: true) { timer in
            currentColorIndex += 1

            if currentColorIndex < colors.count {
                // Crear nueva capa
                let newLayer = NumberLayer(scale: 1, color: colors[currentColorIndex])
                layers.append(newLayer)

                // Animar todas las capas existentes con animación continua y fluida
                withAnimation(.linear(duration: 0.18)) {
                    for index in layers.indices {
                        layers[index].scale += 0.35
                    }
                }
            } else {
                // Cuando termina la expansión, iniciar la contracción
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    contractAndTransition()
                }
            }
        }
    }

    func contractAndTransition() {
        // Contraer todo hacia el centro
        withAnimation(.easeInOut(duration: 1.2)) {
            isContracting = true
        }

        // Después de la contracción, expandir el círculo blanco
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 1.5)) {
                circleScale = 20
            }

            // Ocultar el splash screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showSplash = false
            }
        }
    }
}
