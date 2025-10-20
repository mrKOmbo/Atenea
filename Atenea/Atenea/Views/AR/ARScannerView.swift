//
//  ARScannerView.swift
//  Atenea
//
//  Created by Emilio Cruz Vargas on 08/10/25.
//

import SwiftUI
import AVFoundation

struct ARScannerView: View {
    let onScanRequest: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.green.opacity(0.3), Color.red.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Icon
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .white, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10)

                // Title
                VStack(spacing: 8) {
                    Text("Escanear Poster")
                        .font(.largeTitle.bold())

                    Text("Descubre información de cada sede")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Instructions
                VStack(alignment: .center, spacing: 16) {
                    InstructionRow(number: 1, text: "Busca un poster oficial del Mundial 2026")
                    InstructionRow(number: 2, text: "Apunta tu cámara al poster")
                    InstructionRow(number: 3, text: "Descubre la sede y obtén direcciones")
                }
                .padding(24)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.1), radius: 10)
                .padding(.horizontal, 40)

                // Scan button
                Button(action: {
                    onScanRequest()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                        Text("Iniciar Escaneo")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.2), radius: 10)
                }
                .padding(.horizontal, 30)

                Spacer()
            }
        }
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Number badge
            Text("\(number)")
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    LinearGradient(
                        colors: [.green, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 3)

            // Text
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ARScannerView(onScanRequest: {
        print("Scan requested")
    })
}
