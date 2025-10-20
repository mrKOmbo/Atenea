//
//  LocationSearchManager.swift
//  Atenea
//
//  Gestor de búsqueda de ubicaciones con autocompletado
//  Adaptado del proyecto NASA Space Apps 2025
//

import Foundation
import MapKit
internal import Combine
import CoreLocation

class LocationSearchManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var searchQuery: String = "" {
        didSet {
            if searchQuery.isEmpty {
                searchResults = []
            } else {
                performSearch()
            }
        }
    }

    @Published var searchResults: [SearchResult] = []
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let searchCompleter = MKLocalSearchCompleter()
    private var searchTask: Task<Void, Never>?
    private var searchRegion: MKCoordinateRegion?

    // MARK: - Initialization

    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }

    // MARK: - Public Methods

    func updateSearchRegion(center: CLLocationCoordinate2D, radiusInMeters: Double = 50000) {
        let span = MKCoordinateSpan(
            latitudeDelta: radiusInMeters / 111000,
            longitudeDelta: radiusInMeters / 111000
        )
        searchRegion = MKCoordinateRegion(center: center, span: span)
        searchCompleter.region = searchRegion!
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        errorMessage = nil
        isSearching = false
        searchTask?.cancel()
    }

    func selectResult(_ result: SearchResult, completion: @escaping (CLLocationCoordinate2D?, String) -> Void) {
        if let coordinate = result.coordinate {
            completion(coordinate, result.title)
            return
        }

        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = result.title + " " + result.subtitle

        if let region = searchRegion {
            searchRequest.region = region
        }

        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                self.errorMessage = "Could not find location"
                completion(nil, result.title)
                return
            }

            guard let mapItem = response?.mapItems.first else {
                completion(nil, result.title)
                return
            }

            // Usar location en lugar de placemark (iOS 26+)
            let coordinate = mapItem.location.coordinate
            completion(coordinate, mapItem.name ?? result.title)
        }
    }

    func reverseGeocode(coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("❌ Error en geocodificación: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let placemark = placemarks?.first else {
                completion(nil)
                return
            }

            var addressComponents: [String] = []

            if let name = placemark.name {
                addressComponents.append(name)
            }
            if let locality = placemark.locality {
                addressComponents.append(locality)
            }

            let address = addressComponents.joined(separator: ", ")
            completion(address)
        }
    }

    // MARK: - Private Methods

    private func performSearch() {
        searchTask?.cancel()

        searchTask = Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.isSearching = true
                    self.searchCompleter.queryFragment = self.searchQuery
                }
            } catch {
                // Task cancelled
            }
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension LocationSearchManager: MKLocalSearchCompleterDelegate {

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.searchResults = completer.results.prefix(8).map { completion in
                SearchResult(from: completion)
            }

            self.isSearching = false
            self.errorMessage = nil

            print("🔍 Encontrados \(self.searchResults.count) resultados")
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isSearching = false
            self.errorMessage = "Search failed"
            self.searchResults = []

            print("❌ Error en búsqueda: \(error.localizedDescription)")
        }
    }
}
