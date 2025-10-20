//
//  SearchResult.swift
//  Atenea
//
//  Modelo para resultados de búsqueda de ubicaciones
//  Adaptado del proyecto NASA Space Apps 2025
//

import Foundation
import MapKit
import CoreLocation

// MARK: - Search Result Model

struct SearchResult: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D?
    let mapItem: MKMapItem?

    init(id: UUID = UUID(), title: String, subtitle: String, coordinate: CLLocationCoordinate2D? = nil, mapItem: MKMapItem? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.mapItem = mapItem
    }

    // Inicializador desde MKLocalSearchCompletion
    init(from completion: MKLocalSearchCompletion) {
        self.id = UUID()
        self.title = completion.title
        self.subtitle = completion.subtitle
        self.coordinate = nil
        self.mapItem = nil
    }

    // Inicializador desde MKMapItem
    init(from mapItem: MKMapItem) {
        self.id = UUID()
        self.title = mapItem.name ?? "Unknown"

        // Usar location en lugar de placemark para coordinate
        self.coordinate = mapItem.location.coordinate

        // Para subtitle, construir desde placemark (aún funciona en iOS 26)
        var addressComponents: [String] = []

        if let thoroughfare = mapItem.placemark.thoroughfare {
            addressComponents.append(thoroughfare)
        }
        if let locality = mapItem.placemark.locality {
            addressComponents.append(locality)
        }

        if !addressComponents.isEmpty {
            self.subtitle = addressComponents.joined(separator: ", ")
        } else {
            self.subtitle = mapItem.placemark.title ?? ""
        }

        self.mapItem = mapItem
    }

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: - Helper Properties

    var placeType: PlaceType {
        guard let mapItem = mapItem else { return .generic }

        if let category = mapItem.pointOfInterestCategory {
            switch category {
            case .restaurant, .cafe, .bakery, .brewery, .winery:
                return .food
            case .hotel, .museum, .theater, .movieTheater, .nightlife:
                return .entertainment
            case .store, .pharmacy:
                return .shopping
            case .gasStation, .evCharger, .parking:
                return .transportation
            case .hospital:
                return .health
            case .park, .beach:
                return .nature
            default:
                return .generic
            }
        }

        return .generic
    }
}

// MARK: - Place Type Enum

enum PlaceType {
    case food
    case entertainment
    case shopping
    case transportation
    case health
    case nature
    case generic

    var icon: String {
        switch self {
        case .food:
            return "fork.knife.circle.fill"
        case .entertainment:
            return "theatermasks.circle.fill"
        case .shopping:
            return "cart.circle.fill"
        case .transportation:
            return "car.circle.fill"
        case .health:
            return "cross.circle.fill"
        case .nature:
            return "tree.circle.fill"
        case .generic:
            return "mappin.circle.fill"
        }
    }
}
