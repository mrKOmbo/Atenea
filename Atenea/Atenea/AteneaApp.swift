//
//  AteneaApp.swift
//  Atenea
//
//  Created by Emilio Cruz Vargas on 10/10/25.
//

import SwiftUI

@main
struct AteneaApp: App {
    @StateObject private var languageManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageManager)
        }
    }
}
