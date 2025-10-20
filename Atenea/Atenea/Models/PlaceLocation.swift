//
//  PlaceLocation.swift
//  Atenea
//
//  Created by Claude on 10/15/25.
//

import Foundation
import MapKit
import SwiftUI

// MARK: - Modelo de Lugar

struct PlaceLocation: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let description: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Parser de Respuestas de Claude

class ClaudeResponseParser {

    /// Parsear lugares de la respuesta de Claude
    /// Formato esperado: [LUGAR: Nombre | LAT: 19.4326 | LON: -99.1332]
    static func parsePlaces(from text: String) -> [PlaceLocation] {
        var places: [PlaceLocation] = []

        // Regex para encontrar el patrón [LUGAR: ... | LAT: ... | LON: ...]
        let pattern = #"\[LUGAR:\s*(.+?)\s*\|\s*LAT:\s*([-\d.]+)\s*\|\s*LON:\s*([-\d.]+)\]"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return places
        }

        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            guard match.numberOfRanges == 4 else { continue }

            // Extraer nombre
            let nameRange = match.range(at: 1)
            let name = nsString.substring(with: nameRange).trimmingCharacters(in: .whitespaces)

            // Extraer latitud
            let latRange = match.range(at: 2)
            let latString = nsString.substring(with: latRange)
            guard let latitude = Double(latString) else { continue }

            // Extraer longitud
            let lonRange = match.range(at: 3)
            let lonString = nsString.substring(with: lonRange)
            guard let longitude = Double(lonString) else { continue }

            // Buscar descripción (texto después del corchete de cierre hasta el próximo emoji o salto de línea)
            let endOfPattern = match.range.location + match.range.length
            if endOfPattern < nsString.length {
                let remainingText = nsString.substring(from: endOfPattern)
                let descriptionPattern = #"^\s*-\s*(.+?)(?=\n|$|🌮|🏛️|🎭|🍽️|🏟️|🎨|🌳|🏖️|🎪|🎡)"#
                if let descRegex = try? NSRegularExpression(pattern: descriptionPattern, options: []),
                   let descMatch = descRegex.firstMatch(in: remainingText, options: [], range: NSRange(location: 0, length: min(remainingText.count, 200))),
                   descMatch.numberOfRanges > 1 {
                    let descRange = descMatch.range(at: 1)
                    let description = (remainingText as NSString).substring(with: descRange).trimmingCharacters(in: .whitespacesAndNewlines)

                    places.append(PlaceLocation(
                        name: name,
                        latitude: latitude,
                        longitude: longitude,
                        description: description
                    ))
                } else {
                    places.append(PlaceLocation(
                        name: name,
                        latitude: latitude,
                        longitude: longitude,
                        description: nil
                    ))
                }
            } else {
                places.append(PlaceLocation(
                    name: name,
                    latitude: latitude,
                    longitude: longitude,
                    description: nil
                ))
            }
        }

        return places
    }

    /// Limpiar el texto de respuesta eliminando los marcadores de coordenadas
    /// para mostrar solo el texto limpio
    static func cleanResponse(text: String) -> String {
        let pattern = #"\[LUGAR:\s*(.+?)\s*\|\s*LAT:\s*[-\d.]+\s*\|\s*LON:\s*[-\d.]+\]"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }

        // Reemplazar los marcadores con solo el nombre del lugar
        let nsString = text as NSString
        let mutableString = NSMutableString(string: text)

        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length)).reversed()

        for match in matches {
            if match.numberOfRanges > 1 {
                let nameRange = match.range(at: 1)
                let name = nsString.substring(with: nameRange)
                mutableString.replaceCharacters(in: match.range, with: "📍 \(name)")
            }
        }

        return String(mutableString)
    }

    /// Crear texto con botones clickeables para mostrar en SwiftUI
    static func formatResponseWithLinks(text: String) -> AttributedString {
        var attributedString = AttributedString(cleanResponse(text: text))

        // Aplicar estilos básicos
        attributedString.font = .system(size: 16)
        attributedString.foregroundColor = .white

        return attributedString
    }
}
