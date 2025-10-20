//
//  RecommendationsWatchView.swift
//  AteneaWatch Watch App
//
//  Created by Claude Code
//

import SwiftUI
import CoreLocation

struct RecommendationsWatchView: View {
    @ObservedObject var connectivityManager = WatchConnectivityManager.shared
    @State private var selectedRecommendation: WatchRecommendation?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if connectivityManager.recommendations.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        Text("Recomendaciones")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top, 8)

                        ForEach(connectivityManager.recommendations) { recommendation in
                            RecommendationCard(recommendation: recommendation)
                                .onTapGesture {
                                    selectedRecommendation = recommendation
                                }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
        }
        .sheet(item: $selectedRecommendation) { recommendation in
            RecommendationDetailView(recommendation: recommendation)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "map.circle")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("No hay recomendaciones")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Text("Abre la app en tu iPhone")
                .font(.system(size: 11))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct RecommendationCard: View {
    let recommendation: WatchRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Encabezado con nombre y ubicación
            VStack(alignment: .leading, spacing: 3) {
                Text(recommendation.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.7))

                    Text("\(recommendation.city), \(recommendation.country)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Divider()
                .background(Color.white.opacity(0.3))
                .padding(.vertical, 2)

            // Próximo partido
            if let nextMatch = recommendation.nextMatch {
                HStack(spacing: 4) {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.9))

                    Text(nextMatch)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                }
            }

            // Dato curioso (si existe)
            if let funFact = recommendation.funFact, !funFact.isEmpty {
                Text(funFact)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: recommendation.hexColor).opacity(0.7),
                            Color(hex: recommendation.hexColor).opacity(0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color(hex: recommendation.hexColor).opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

struct RecommendationDetailView: View {
    let recommendation: WatchRecommendation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Encabezado
                VStack(alignment: .leading, spacing: 6) {
                    Text(recommendation.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text("\(recommendation.city), \(recommendation.country)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 8)

                Divider()
                    .background(Color.white.opacity(0.3))

                // Próximo partido
                if let nextMatch = recommendation.nextMatch {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Próximo partido", systemImage: "sportscourt.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))

                        Text(nextMatch)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }

                // Dato curioso
                if let funFact = recommendation.funFact, !funFact.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Dato curioso", systemImage: "lightbulb.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))

                        Text(funFact)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.top, 4)
                }

                Spacer(minLength: 12)

                // Botón cerrar
                Button(action: { dismiss() }) {
                    Text("Cerrar")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: recommendation.hexColor).opacity(0.6))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(Color.black)
    }
}

// Extension para Color desde hex (si no existe ya)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    RecommendationsWatchView()
}
