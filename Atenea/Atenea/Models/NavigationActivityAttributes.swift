//
//  NavigationActivityAttributes.swift
//  Atenea
//
//  Activity Attributes para Live Activities de navegación
//

import Foundation
import ActivityKit

struct NavigationActivityAttributes: ActivityAttributes {

    // MARK: - Content State (Datos dinámicos)
    public struct ContentState: Codable, Hashable {
        var currentInstruction: String
        var distanceRemaining: Double  // en metros
        var timeRemaining: Double      // en segundos
    }

    // MARK: - Static Data (Datos estáticos)
    var destinationName: String
}
