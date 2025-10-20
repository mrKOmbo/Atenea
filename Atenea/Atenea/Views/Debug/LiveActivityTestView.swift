//
//  LiveActivityTestView.swift
//  Atenea
//
//  Vista de debug para probar Live Activities
//

import SwiftUI
import ActivityKit

struct LiveActivityTestView: View {
    @State private var testActivity: Activity<NavigationActivityAttributes>?
    @State private var statusMessage: String = "Presiona para probar"
    @State private var isActivityActive: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("🧪 Live Activity Test")
                .font(.system(size: 24, weight: .bold))

            Text(statusMessage)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()

            // Botón para iniciar
            Button(action: startTestActivity) {
                Text("Iniciar Live Activity")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .disabled(isActivityActive)

            // Botón para actualizar
            Button(action: updateTestActivity) {
                Text("Actualizar Live Activity")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .disabled(!isActivityActive)

            // Botón para detener
            Button(action: stopTestActivity) {
                Text("Detener Live Activity")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
            }
            .disabled(!isActivityActive)

            Divider()
                .padding(.vertical)

            VStack(alignment: .leading, spacing: 8) {
                Text("Información del Sistema:")
                    .font(.system(size: 14, weight: .bold))

                InfoRow(label: "Live Activities habilitadas", value: "\(ActivityAuthorizationInfo().areActivitiesEnabled)")
                InfoRow(label: "Actividades activas", value: "\(Activity<NavigationActivityAttributes>.activities.count)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
    }

    func startTestActivity() {
        print("🧪 [TEST] Iniciando Live Activity de prueba...")

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            statusMessage = "❌ Live Activities deshabilitadas\nVe a Configuración > Notificaciones"
            print("🧪 [TEST] ❌ Live Activities no habilitadas")
            return
        }

        let attributes = NavigationActivityAttributes(destinationName: "Estadio Azteca")
        let initialState = NavigationActivityAttributes.ContentState(
            currentInstruction: "Prueba de Live Activity",
            distanceRemaining: 5000,
            timeRemaining: 600
        )

        do {
            testActivity = try Activity<NavigationActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            isActivityActive = true
            statusMessage = "✅ Live Activity iniciada!\nID: \(testActivity?.id ?? "unknown")\n\nAhora presiona Home y mira la Dynamic Island"

            print("🧪 [TEST] ✅ Live Activity creada exitosamente")
            print("🧪 [TEST] Activity ID: \(testActivity?.id ?? "unknown")")
        } catch {
            statusMessage = "❌ Error: \(error.localizedDescription)"
            print("🧪 [TEST] ❌ Error: \(error)")
        }
    }

    func updateTestActivity() {
        guard let activity = testActivity else { return }

        print("🧪 [TEST] Actualizando Live Activity...")

        let updatedState = NavigationActivityAttributes.ContentState(
            currentInstruction: "Actualización \(Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 100))",
            distanceRemaining: Double.random(in: 100...5000),
            timeRemaining: Double.random(in: 60...600)
        )

        Task {
            await activity.update(using: updatedState)
            statusMessage = "✅ Live Activity actualizada\n\(Date().formatted(.dateTime.hour().minute().second()))"
            print("🧪 [TEST] ✅ Actualizada")
        }
    }

    func stopTestActivity() {
        guard let activity = testActivity else { return }

        print("🧪 [TEST] Deteniendo Live Activity...")

        Task {
            await activity.end(using: nil, dismissalPolicy: .immediate)
            testActivity = nil
            isActivityActive = false
            statusMessage = "✅ Live Activity detenida"
            print("🧪 [TEST] ✅ Detenida")
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
        }
    }
}

#Preview {
    LiveActivityTestView()
}
