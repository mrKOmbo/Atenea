//
//  AteneaWidgets.swift
//  AteneaWidgets
//
//  Widget Extension para Live Activities con Dynamic Island
//

import ActivityKit
import WidgetKit
import SwiftUI

@main
struct AteneaWidgetsBundle: WidgetBundle {
    var body: some Widget {
        NavigationLiveActivity()
    }
}

struct NavigationLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NavigationActivityAttributes.self) { context in
            // MARK: - Lock Screen / Banner View
            VStack(spacing: 12) {
                // Header con destino
                HStack(spacing: 12) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "#00D084"))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Navigating to")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))

                        Text(context.attributes.destinationName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }

                    Spacer()
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // Instrucción actual
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#C8FF00"))

                    Text(context.state.currentInstruction)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Spacer()
                }

                // ETA y Distancia
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text(formatTime(context.state.timeRemaining))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("ETA")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Text(formatDistance(context.state.distanceRemaining))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("Distance")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            .activityBackgroundTint(Color.black.opacity(0.95))
            .activitySystemActionForegroundColor(Color(hex: "#00D084"))

        } dynamicIsland: { context in
            // MARK: - Dynamic Island
            DynamicIsland {
                // MARK: Expanded - Leading
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "#00D084"))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.destinationName)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(context.state.currentInstruction)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                }

                // MARK: Expanded - Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatTime(context.state.timeRemaining))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .monospacedDigit()

                        Text("ETA")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                // MARK: Expanded - Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#C8FF00"))

                        Text(formatDistance(context.state.distanceRemaining))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .monospacedDigit()

                        Spacer()

                        Text("remaining")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }

            } compactLeading: {
                // MARK: Compact - Leading
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "#00D084"))
                }

            } compactTrailing: {
                // MARK: Compact - Trailing
                Text(formatTime(context.state.timeRemaining))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .monospacedDigit()

            } minimal: {
                // MARK: Minimal
                Image(systemName: "location.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#00D084"))
            }
        }
    }

    // MARK: - Helper Functions

    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            let km = meters / 1000
            if km < 10 {
                return String(format: "%.1f km", km)
            } else {
                return "\(Int(km)) km"
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "< 1 min"
        }
    }
}

// MARK: - Color Extension
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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
