//
//  APIKeySettingsView.swift
//  Atenea
//
//  Vista para configurar API key de Claude
//

import SwiftUI

struct APIKeySettingsView: View {
    @Binding var isPresented: Bool
    @State private var apiKey: String = APIConfiguration.shared.claudeAPIKey
    @State private var showSavedMessage: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fondo oscuro
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    }

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 50)

                    // Panel principal
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("Claude API Settings")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Spacer()

                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    isPresented = false
                                }
                            }) {
                                Circle()
                                    .fill(Color(white: 0.15))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "xmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 24)

                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                // Instrucciones
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("API Key Configuration")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)

                                    Text("To use the AI chat features, you need to provide your Claude API key. You can get one from:")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.7))
                                        .fixedSize(horizontal: false, vertical: true)

                                    Link(destination: URL(string: "https://console.anthropic.com")!) {
                                        HStack {
                                            Text("console.anthropic.com")
                                                .font(.system(size: 15, weight: .medium))
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 12))
                                        }
                                        .foregroundColor(Color(hex: "#00D084"))
                                    }
                                }

                                Divider()
                                    .background(Color.white.opacity(0.1))

                                // Campo de API Key
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("API Key")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)

                                    SecureField("sk-ant-...", text: $apiKey)
                                        .font(.system(size: 15, design: .monospaced))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(Color(white: 0.12))
                                        .cornerRadius(12)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()

                                    Text("Your API key is stored securely on your device and is never shared.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.5))
                                }

                                // Botón guardar
                                Button(action: {
                                    saveAPIKey()
                                }) {
                                    HStack {
                                        Image(systemName: showSavedMessage ? "checkmark.circle.fill" : "square.and.arrow.down")
                                            .font(.system(size: 16, weight: .semibold))

                                        Text(showSavedMessage ? "Saved!" : "Save API Key")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(showSavedMessage ? Color(hex: "#00D084") : Color(hex: "#C8FF00"))
                                    )
                                }
                                .disabled(apiKey.isEmpty)
                                .opacity(apiKey.isEmpty ? 0.5 : 1.0)

                                // Información de seguridad
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "lock.shield.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "#00D084"))

                                        Text("Security & Privacy")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }

                                    Text("• Your API key is encrypted and stored locally\n• Never shared with third parties\n• You can delete it anytime\n• Standard API usage charges apply from Anthropic")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.6))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.top, 8)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: geometry.size.height - 50)
                    .background(Color.black)
                    .clipShape(
                        RoundedCorner(radius: 30, corners: [.topLeft, .topRight])
                    )
                }
            }
        }
    }

    private func saveAPIKey() {
        APIConfiguration.shared.claudeAPIKey = apiKey

        withAnimation {
            showSavedMessage = true
        }

        // Resetear mensaje después de 2 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showSavedMessage = false
            }
        }
    }
}

#Preview {
    APIKeySettingsView(isPresented: .constant(true))
}
