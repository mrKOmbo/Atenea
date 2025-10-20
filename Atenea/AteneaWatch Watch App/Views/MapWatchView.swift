//
//  MapWatchView.swift
//  AteneaWatch Watch App
//
//  Created by Claude Code
//

import SwiftUI
import MapKit

struct MapWatchView: View {
    @ObservedObject var connectivityManager = WatchConnectivityManager.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )

    var body: some View {
        ZStack {
            // Mapa de fondo
            Map(coordinateRegion: $region, showsUserLocation: true)
                .edgesIgnoringSafeArea(.all)

            // Overlay con información
            VStack {
                Spacer()

                // Información en la parte inferior
                VStack(spacing: 4) {
                    Text("Mundial 2026")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)

                    Text("Explora las sedes")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.7))
                        .shadow(radius: 5)
                )
                .padding(.bottom, 10)
            }
        }
        .onAppear {
            updateRegion()
        }
    }

    private func updateRegion() {
        // Centrar en las sedes del Mundial 2026
        // Coordenadas aproximadas del centro de Norteamérica
        let center = CLLocationCoordinate2D(
            latitude: 39.8283,  // Centro de USA
            longitude: -98.5795
        )

        region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 40.0, longitudeDelta: 40.0)
        )
    }
}

#Preview {
    MapWatchView()
}
