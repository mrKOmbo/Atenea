//
//  WatchRecommendation.swift
//  AteneaWatch Watch App
//
//  Created by Claude Code
//

import Foundation
import CoreLocation

/// Modelo simplificado de recomendación para Apple Watch
struct WatchRecommendation: Identifiable, Codable {
    let id: String
    let name: String
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double
    let hexColor: String
    let nextMatch: String?
    let funFact: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Inicializador desde diccionario (para Watch Connectivity)
    init?(from dict: [String: Any]) {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let city = dict["city"] as? String,
              let country = dict["country"] as? String,
              let latitude = dict["latitude"] as? Double,
              let longitude = dict["longitude"] as? Double,
              let hexColor = dict["hexColor"] as? String else {
            return nil
        }

        self.id = id
        self.name = name
        self.city = city
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.hexColor = hexColor
        self.nextMatch = dict["nextMatch"] as? String
        self.funFact = dict["funFact"] as? String
    }

    /// Inicializador completo
    init(id: String, name: String, city: String, country: String, latitude: Double, longitude: Double, hexColor: String, nextMatch: String? = nil, funFact: String? = nil) {
        self.id = id
        self.name = name
        self.city = city
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.hexColor = hexColor
        self.nextMatch = nextMatch
        self.funFact = funFact
    }

    /// Convierte a diccionario para Watch Connectivity
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "city": city,
            "country": country,
            "latitude": latitude,
            "longitude": longitude,
            "hexColor": hexColor
        ]

        if let nextMatch = nextMatch {
            dict["nextMatch"] = nextMatch
        }

        if let funFact = funFact {
            dict["funFact"] = funFact
        }

        return dict
    }
}
