//
//  RecommendationMarker.swift
//  Atenea
//
//  Modelo para marcadores de recomendaciones (restaurantes, cafés, bares, etc.)
//

import Foundation
import MapKit

struct RecommendationMarker: Identifiable, Equatable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let name: String
    let category: String
    let address: String?

    // Equatable implementation
    static func == (lhs: RecommendationMarker, rhs: RecommendationMarker) -> Bool {
        lhs.id == rhs.id
    }
}
