//
//  TransportType.swift
//  Atenea
//
//  Created by Emilio Cruz Vargas on 10/10/25.
//

import SwiftUI

enum TransportType: String, CaseIterable, Identifiable {
    case metro = "Metro"
    case metrobus = "Metrobús"
    case ecobici = "Ecobici"
    case micro = "Microbús"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .metro:
            return "tram.fill"
        case .metrobus:
            return "bus.fill"
        case .ecobici:
            return "bicycle"
        case .micro:
            return "bus"
        }
    }

    var color: Color {
        switch self {
        case .metro:
            return Color(hex: "#F77E0B") // Naranja Metro CDMX
        case .metrobus:
            return Color(hex: "#D12229") // Rojo Metrobús
        case .ecobici:
            return Color(hex: "#ED1C24") // Rojo Ecobici
        case .micro:
            return Color(hex: "#00A99D") // Verde-azul Microbús
        }
    }

    var description: String {
        switch self {
        case .metro:
            return "Sistema de Transporte Colectivo"
        case .metrobus:
            return "Autobús de Tránsito Rápido"
        case .ecobici:
            return "Sistema de Bicicletas Públicas"
        case .micro:
            return "Transporte Colectivo"
        }
    }
}
