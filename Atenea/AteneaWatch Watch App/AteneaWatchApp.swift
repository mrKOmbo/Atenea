//
//  AteneaWatchApp.swift
//  AteneaWatch Watch App
//
//  Created by Emilio Cruz Vargas on 15/10/25.
//

import SwiftUI

@main
struct AteneaWatch_Watch_AppApp: App {
    init() {
        // Inicializar WatchConnectivity al arrancar la app
        _ = WatchConnectivityManager.shared
        print("✅ AteneaWatch app initialized with WatchConnectivity")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
