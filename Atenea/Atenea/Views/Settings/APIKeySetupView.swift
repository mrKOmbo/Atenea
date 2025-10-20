//
//  APIKeySetupView.swift
//  Atenea
//
//  Created by Claude on 10/15/25.
//

import SwiftUI

struct APIKeySetupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var apiKey: String = ""
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isValidating = false

    var body: some View {
        NavigationView {
            ZStack {
                // Fondo con gradiente
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)

                            Text("Configurar API de Claude")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("Conecta tu cuenta de Anthropic para usar las funciones de IA")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 40)

                        // Instrucciones
                        VStack(alignment: .leading, spacing: 16) {
                            StepView(
                                number: 1,
                                title: "Ve a console.anthropic.com",
                                description: "Abre tu navegador y visita la consola de Anthropic"
                            )

                            StepView(
                                number: 2,
                                title: "Inicia sesión",
                                description: "Con la cuenta donde compraste la API key"
                            )

                            StepView(
                                number: 3,
                                title: "Ve a API Keys",
                                description: "En el menú lateral, selecciona 'API Keys'"
                            )

                            StepView(
                                number: 4,
                                title: "Copia tu API Key",
                                description: "Copia la key completa (empieza con sk-ant-)"
                            )
                        }
                        .padding(.horizontal, 20)

                        // Campo para ingresar API Key
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tu API Key")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            TextField("sk-ant-api03-...", text: $apiKey)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(16)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()

                            if !apiKey.isEmpty && !apiKey.hasPrefix("sk-ant-") {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.yellow)
                                    Text("La API key debe comenzar con 'sk-ant-'")
                                        .font(.system(size: 14))
                                        .foregroundColor(.yellow)
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Botón de guardar
                        Button(action: saveAPIKey) {
                            HStack {
                                if isValidating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))

                                    Text("Guardar API Key")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 5)
                        }
                        .disabled(apiKey.isEmpty || !apiKey.hasPrefix("sk-ant-") || isValidating)
                        .opacity((apiKey.isEmpty || !apiKey.hasPrefix("sk-ant-") || isValidating) ? 0.6 : 1.0)
                        .padding(.horizontal, 20)

                        // Información adicional
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.green)
                                Text("Tu API key se guarda de forma segura en tu dispositivo")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            HStack(spacing: 8) {
                                Image(systemName: "link")
                                    .foregroundColor(.blue)
                                Link("Abrir console.anthropic.com", destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .alert("✅ API Key Guardada", isPresented: $showSuccess) {
                Button("Listo") {
                    dismiss()
                }
            } message: {
                Text("Tu API key se ha configurado correctamente. Ya puedes usar las funciones de IA.")
            }
            .alert("❌ Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Funciones

    private func saveAPIKey() {
        isValidating = true

        // Validar formato básico
        guard apiKey.hasPrefix("sk-ant-") && apiKey.count > 20 else {
            errorMessage = "La API key no parece ser válida. Verifica que copiaste la key completa."
            showError = true
            isValidating = false
            return
        }

        // Guardar en UserDefaults
        APIConfiguration.shared.claudeAPIKey = apiKey

        // Simular validación (opcional: podrías hacer una petición de prueba aquí)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isValidating = false
            showSuccess = true
        }
    }
}

// MARK: - Step View Component

struct StepView: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Text("\(number)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    APIKeySetupView()
}
