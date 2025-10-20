//
//  NativeMapView.swift
//  Atenea
//
//  Created by Claude on 10/13/25.
//

import SwiftUI
import MapKit

struct NativeMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var venues: [WorldCupVenue]
    var onVenueSelected: (WorldCupVenue) -> Void
    var onUserLocationLongPress: (CLLocationCoordinate2D) -> Void // Callback para long press en ubicación del usuario
    var shouldFollowUserWithHeading: Bool = true // Control para activar heading
    var mapMode: MapMode = .explore // Tipo de mapa a mostrar

    // NUEVOS PARÁMETROS PARA DIRECCIONES
    var routePolylines: [MKPolyline] = []
    var selectedRouteIndex: Int = 0
    var onMapTap: ((CLLocationCoordinate2D) -> Void)? = nil
    var selectedDestination: CLLocationCoordinate2D? = nil

    // NUEVOS PARÁMETROS PARA MARCADORES DE RECOMENDACIONES
    var recommendationMarkers: [RecommendationMarker] = []

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        // IMPORTANTE: Esto activa el indicador azul con heading automático
        mapView.showsUserLocation = true

        // Configuración del mapa
        mapView.mapType = mapMode.mkMapType
        mapView.showsCompass = true
        mapView.showsScale = true

        // CRÍTICO: Permitir interacción con anotaciones
        mapView.isUserInteractionEnabled = true

        // NUEVO: Agregar tap gesture para seleccionar destinos en el mapa
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        tapGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(tapGesture)

        print("🗺️ MapView creado con delegate y tap gesture configurado")

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Guardar referencia al coordinator
        context.coordinator.parent = self

        // Actualizar el tipo de mapa si cambió
        if mapView.mapType != mapMode.mkMapType {
            mapView.mapType = mapMode.mkMapType
            print("🗺️ Tipo de mapa cambiado a: \(mapMode.rawValue)")
        }

        // Si queremos seguir al usuario con heading, activar ese modo
        if shouldFollowUserWithHeading {
            if mapView.userTrackingMode != .followWithHeading {
                mapView.setUserTrackingMode(.followWithHeading, animated: true)
                print("🧭 Activando userTrackingMode.followWithHeading")
            }
        } else {
            // Solo actualizar región si NO estamos siguiendo al usuario
            if mapView.region.center.latitude != region.center.latitude ||
               mapView.region.center.longitude != region.center.longitude {
                mapView.setRegion(region, animated: true)
            }
        }

        // NUEVO: Actualizar polylines de rutas
        mapView.removeOverlays(mapView.overlays)
        if !routePolylines.isEmpty {
            mapView.addOverlays(routePolylines)
            print("🛣️ Añadidas \(routePolylines.count) polylines al mapa")
        }

        // NUEVO: Actualizar anotación de destino seleccionado
        // Remover anotación anterior de destino si existe
        let existingDestinationAnnotations = mapView.annotations.compactMap { $0 as? DestinationAnnotation }
        if !existingDestinationAnnotations.isEmpty {
            mapView.removeAnnotations(existingDestinationAnnotations)
        }

        // Agregar nueva anotación de destino si existe
        if let destination = selectedDestination {
            let destinationAnnotation = DestinationAnnotation(coordinate: destination)
            mapView.addAnnotation(destinationAnnotation)
            print("📍 Destino seleccionado añadido al mapa")
        }

        // Actualizar anotaciones SOLO si cambiaron
        // Obtener anotaciones actuales de venues (sin user location ni tapped locations)
        let currentVenueAnnotations = mapView.annotations.compactMap { $0 as? VenueAnnotation }

        // Comparar por nombre y ciudad (propiedades únicas)
        let currentVenueKeys = Set(currentVenueAnnotations.map { "\($0.venue.name)-\($0.venue.city)" })
        let newVenueKeys = Set(venues.map { "\($0.name)-\($0.city)" })

        // Solo actualizar si hay diferencias
        if currentVenueKeys != newVenueKeys {
            // Remover anotaciones que ya no están en la lista
            let annotationsToRemove = currentVenueAnnotations.filter {
                !newVenueKeys.contains("\($0.venue.name)-\($0.venue.city)")
            }
            if !annotationsToRemove.isEmpty {
                mapView.removeAnnotations(annotationsToRemove)
            }

            // Agregar nuevas anotaciones que no existen
            let venueKeysToAdd = newVenueKeys.subtracting(currentVenueKeys)
            let newAnnotations = venues.filter {
                venueKeysToAdd.contains("\($0.name)-\($0.city)")
            }.map { VenueAnnotation(venue: $0) }

            if !newAnnotations.isEmpty {
                mapView.addAnnotations(newAnnotations)
            }
        }

        // NUEVO: Actualizar anotaciones de recomendaciones (restaurantes, cafés, etc.)
        let currentRecommendationAnnotations = mapView.annotations.compactMap { $0 as? RecommendationAnnotation }

        // Comparar por ID único
        let currentRecommendationIDs = Set(currentRecommendationAnnotations.map { $0.marker.id })
        let newRecommendationIDs = Set(recommendationMarkers.map { $0.id })

        // Solo actualizar si hay diferencias
        if currentRecommendationIDs != newRecommendationIDs {
            // Remover anotaciones que ya no están en la lista
            let recommendationAnnotationsToRemove = currentRecommendationAnnotations.filter {
                !newRecommendationIDs.contains($0.marker.id)
            }
            if !recommendationAnnotationsToRemove.isEmpty {
                mapView.removeAnnotations(recommendationAnnotationsToRemove)
                print("🗑️ Removidas \(recommendationAnnotationsToRemove.count) anotaciones de recomendaciones")
            }

            // Agregar nuevas anotaciones que no existen
            let recommendationIDsToAdd = newRecommendationIDs.subtracting(currentRecommendationIDs)
            let newRecommendationAnnotations = recommendationMarkers.filter {
                recommendationIDsToAdd.contains($0.id)
            }.map { RecommendationAnnotation(marker: $0) }

            if !newRecommendationAnnotations.isEmpty {
                mapView.addAnnotations(newRecommendationAnnotations)
                print("📍 Añadidas \(newRecommendationAnnotations.count) anotaciones de recomendaciones")
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: NativeMapView

        init(_ parent: NativeMapView) {
            self.parent = parent
        }

        // ✅ PASO 1: DECIDIR QUÉ GESTO DEBE RECIBIR EL TOQUE
        // Este método evita que el gesto de toque genérico se active si el toque fue sobre un marcador.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            // Si la vista tocada es una vista de marcador (MKAnnotationView), no proceses el gesto genérico.
            // Deja que el mapa maneje la selección del marcador.
            if touch.view is MKAnnotationView {
                print("🚫 Tap en anotación - bloqueando gesture genérico")
                return false
            }
            return true
        }

        // ✅ PASO 2: MANEJAR EL TOQUE GENÉRICO EN EL MAPA
        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }

            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

            print("🗺️ Tap en mapa: \(coordinate.latitude), \(coordinate.longitude)")
            parent.onMapTap?(coordinate)
        }

        // NUEVO: Permitir que el tap gesture coexista con otros gestos
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Vista personalizada para la ubicación del usuario
            if annotation is MKUserLocation {
                print("👤 Creando vista para ubicación del usuario")
                let identifier = "UserLocation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

                if annotationView == nil {
                    print("🆕 Creando nueva annotation view")
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = false

                    // CRÍTICO: Habilitar interacción ANTES de configurar cualquier cosa
                    annotationView?.isUserInteractionEnabled = true

                    // Configurar imagen personalizada del usuario desde Assets
                    if let userImage = UIImage(named: "User") {
                        print("🖼️ Imagen User encontrada en Assets")
                        // Redimensionar y hacer circular la imagen
                        let size = CGSize(width: 60, height: 60)
                        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                        let rect = CGRect(origin: .zero, size: size)

                        // Crear path circular
                        let path = UIBezierPath(ovalIn: rect)
                        path.addClip()

                        userImage.draw(in: rect)
                        let circularImage = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()

                        annotationView?.image = circularImage

                        // Añadir borde blanco y sombra
                        annotationView?.layer.borderColor = UIColor.white.cgColor
                        annotationView?.layer.borderWidth = 3
                        annotationView?.layer.cornerRadius = 30
                        annotationView?.layer.shadowColor = UIColor.black.cgColor
                        annotationView?.layer.shadowOpacity = 0.3
                        annotationView?.layer.shadowOffset = CGSize(width: 0, height: 2)
                        annotationView?.layer.shadowRadius = 4
                        annotationView?.layer.masksToBounds = false
                    } else {
                        print("⚠️ No se encontró imagen User en Assets")
                    }

                    // Añadir long press gesture para compartir ubicación
                    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
                    longPress.minimumPressDuration = 0.5
                    longPress.cancelsTouchesInView = false
                    annotationView?.addGestureRecognizer(longPress)

                    print("✅ Annotation view configurada con gestos - isUserInteractionEnabled: \(annotationView?.isUserInteractionEnabled ?? false)")
                } else {
                    print("♻️ Reutilizando annotation view existente")
                    annotationView?.annotation = annotation
                    // Asegurar que sigue siendo interactiva
                    annotationView?.isUserInteractionEnabled = true
                }

                return annotationView
            }

            // NUEVO: Manejar anotación de destino seleccionado
            if annotation is DestinationAnnotation {
                let identifier = "DestinationMarker"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.markerTintColor = .systemRed
                    annotationView?.glyphImage = UIImage(systemName: "mappin")
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }

                return annotationView
            }

            // Manejar nuestras anotaciones de venues
            if let venueAnnotation = annotation as? VenueAnnotation {
                let identifier = "VenueMarker"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = false

                    // ✅ CRÍTICO: Habilitar interacción para que los toques funcionen
                    annotationView?.isUserInteractionEnabled = true

                    print("🏟️ Creando nueva venue annotation view")
                }

                annotationView?.annotation = annotation

                // Limpiar subvistas anteriores
                annotationView?.subviews.forEach { $0.removeFromSuperview() }

                // Crear vista personalizada con SwiftUI
                let hostingController = UIHostingController(
                    rootView: VenueMarker(venue: venueAnnotation.venue, isSelected: false)
                )
                hostingController.view.backgroundColor = .clear
                hostingController.view.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
                hostingController.view.isUserInteractionEnabled = false  // ✅ Importante: desactivar en la subvista para que los toques pasen al annotationView

                annotationView?.addSubview(hostingController.view)

                return annotationView
            }

            // NUEVO: Manejar anotaciones de recomendaciones (restaurantes, cafés, etc.)
            if let recommendationAnnotation = annotation as? RecommendationAnnotation {
                let identifier = "RecommendationMarker"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                    annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                } else {
                    annotationView?.annotation = annotation
                }

                // Color según la categoría
                let category = recommendationAnnotation.marker.category.lowercased()
                switch category {
                case "restaurants", "dinner":
                    annotationView?.markerTintColor = .systemOrange
                    annotationView?.glyphImage = UIImage(systemName: "fork.knife")
                case "coffee", "café", "cafe":
                    annotationView?.markerTintColor = .systemBrown
                    annotationView?.glyphImage = UIImage(systemName: "cup.and.saucer.fill")
                case "bars", "bar":
                    annotationView?.markerTintColor = .systemPurple
                    annotationView?.glyphImage = UIImage(systemName: "wineglass.fill")
                case "hotels", "hotel":
                    annotationView?.markerTintColor = .systemBlue
                    annotationView?.glyphImage = UIImage(systemName: "bed.double.fill")
                case "museums", "museum":
                    annotationView?.markerTintColor = .systemRed
                    annotationView?.glyphImage = UIImage(systemName: "building.columns.fill")
                case "gyms", "gym":
                    annotationView?.markerTintColor = .systemGreen
                    annotationView?.glyphImage = UIImage(systemName: "figure.strengthtraining.traditional")
                case "parks", "park":
                    annotationView?.markerTintColor = .systemGreen
                    annotationView?.glyphImage = UIImage(systemName: "tree.fill")
                default:
                    annotationView?.markerTintColor = .systemGray
                    annotationView?.glyphImage = UIImage(systemName: "mappin.circle.fill")
                }

                return annotationView
            }

            return nil
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                print("🔥 Long press detectado!")

                // Obtener la ubicación del usuario
                guard let annotationView = gesture.view as? MKAnnotationView,
                      let userLocation = annotationView.annotation as? MKUserLocation else {
                    print("⚠️ No se pudo obtener la ubicación del usuario")
                    return
                }

                let coordinate = userLocation.coordinate
                print("📍 Coordenadas: \(coordinate.latitude), \(coordinate.longitude)")

                // Feedback háptico
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

                // Llamar al closure del parent para mostrar el sheet bonito
                parent.onUserLocationLongPress(coordinate)
            }
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let venueAnnotation = view.annotation as? VenueAnnotation {
                parent.onVenueSelected(venueAnnotation.venue)
            }
        }

        // Detectar cuando cambia el modo de tracking (usuario mueve el mapa manualmente)
        func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
            print("🗺️ User tracking mode cambió a: \(mode.rawValue)")
        }

        // CRÍTICO: Este método se llama cuando la ubicación del usuario se actualiza
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            print("📍 Ubicación actualizada en el mapa: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
            if let heading = userLocation.heading {
                print("🧭 Heading disponible: \(heading.trueHeading)°")
            }
        }

        // NUEVO: Renderizar polylines de rutas
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)

                // Encontrar el índice de esta polyline
                let index = parent.routePolylines.firstIndex(where: { $0 === polyline }) ?? 0
                let isSelected = index == parent.selectedRouteIndex

                if isSelected {
                    // Ruta seleccionada: verde brillante (BrandGreen #00D084)
                    renderer.strokeColor = UIColor(red: 0.0, green: 0.816, blue: 0.518, alpha: 1.0)
                    renderer.lineWidth = 7
                } else {
                    // Rutas alternativas: verde más claro
                    renderer.strokeColor = UIColor(red: 0.46, green: 0.76, blue: 0.48, alpha: 0.7)
                    renderer.lineWidth = 5
                }

                renderer.lineCap = .round
                renderer.lineJoin = .round

                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// Clase de anotación personalizada para venues
class VenueAnnotation: NSObject, MKAnnotation {
    let venue: WorldCupVenue
    var coordinate: CLLocationCoordinate2D {
        return venue.coordinate
    }
    var title: String? {
        return venue.city
    }

    init(venue: WorldCupVenue) {
        self.venue = venue
        super.init()
    }
}

// NUEVO: Clase de anotación para destino seleccionado
class DestinationAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?

    init(coordinate: CLLocationCoordinate2D, title: String? = "Selected Destination") {
        self.coordinate = coordinate
        self.title = title
        super.init()
    }
}

// NUEVO: Clase de anotación para marcadores de recomendaciones (restaurantes, cafés, etc.)
class RecommendationAnnotation: NSObject, MKAnnotation {
    let marker: RecommendationMarker
    var coordinate: CLLocationCoordinate2D {
        return marker.coordinate
    }
    var title: String? {
        return marker.name
    }
    var subtitle: String? {
        return marker.address
    }

    init(marker: RecommendationMarker) {
        self.marker = marker
        super.init()
    }
}
