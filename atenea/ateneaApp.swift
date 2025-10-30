//
//  ateneaApp.swift
//  atenea
//
//  Created by Enrique Calderon on 22/10/25.
//

import SwiftUI

@main
struct ateneaApp: App {
    // Create an instance of the manager that will live for the app's entire lifecycle
    @State private var multipeerManager = MultipeerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Inject the manager into the environment
                .environment(multipeerManager)
        }
    }
}
