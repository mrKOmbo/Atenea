//
//  ScanningOverlayView.swift
//  LiDAR3DScanner
//
//  Vista de overlay durante el escaneo
//

import SwiftUI

struct ScanningOverlayView: View {
    @ObservedObject var viewModel: ARViewModel
    
    var body: some View {
        VStack {
            // Header con estado
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LiDAR Scanner 360°")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    if viewModel.isScanning {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("Escaneando...")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                    } else if viewModel.scanCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Escaneo Completado")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                        }
                    } else {
                        Text("Listo para escanear")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            
            Spacer()
            
            // Guia visual de escaneo
            if viewModel.isScanning {
                ScanningGuideView()
                    .padding(.bottom, 200)
            }
        }
    }
}

struct ScanningGuideView: View {
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Circulo de guia 360 grados
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(
                        Animation.linear(duration: 2.0).repeatForever(autoreverses: false),
                        value: rotationAngle
                    )
                
                VStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                    Text("360")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                rotationAngle = 360
            }
            
            // Consejos rapidos
            HStack(spacing: 20) {
                VStack {
                    Image(systemName: "tortoise.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                    Text("Lento")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                
                VStack {
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    Text("Gira")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                
                VStack {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.purple)
                    Text("Cubre todo")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.6))
            .cornerRadius(12)
        }
    }
}
