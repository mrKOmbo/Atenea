//
//  LanguageManager.swift
//  Atenea
//
//  Manages app language and localization
//

import Foundation
import SwiftUI
internal import Combine

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var currentLanguage: String = "en"

    private init() {
        // Get current language from UserDefaults or system
        if let preferredLanguage = UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first {
            currentLanguage = preferredLanguage
        } else {
            currentLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        }
    }

    // MARK: - Language Methods

    func setLanguage(_ languageCode: String) {
        currentLanguage = languageCode
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        print("🌐 Language changed to: \(languageCode)")
    }

    func localizedString(_ key: String, comment: String = "") -> String {
        guard let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: comment)
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    // MARK: - Country to Language Mapping

    static func languageForCountry(_ country: String) -> String {
        let mapping: [String: String] = [
            // Spanish-speaking countries
            "Mexico": "es",
            "Argentina": "es",
            "Spain": "es",
            "Colombia": "es",
            "Chile": "es",
            "Peru": "es",
            "Ecuador": "es",
            "Uruguay": "es",

            // English-speaking countries
            "United States": "en",
            "Canada": "en", // Note: Canada is bilingual, defaulting to English
            "England": "en",
            "Australia": "en",
            "Nigeria": "en",
            "Ghana": "en",

            // Portuguese-speaking
            "Brazil": "pt",

            // French-speaking
            "France": "fr",
            "Belgium": "fr",
            "Morocco": "fr",
            "Senegal": "fr",

            // German-speaking
            "Germany": "de",

            // Italian-speaking
            "Italy": "it",

            // Dutch-speaking
            "Netherlands": "nl",

            // Portuguese-speaking
            "Portugal": "pt",

            // Japanese-speaking
            "Japan": "ja",

            // Korean-speaking
            "South Korea": "ko",

            // Default to English for others
            "Other": "en"
        ]

        return mapping[country] ?? "en"
    }

    // MARK: - Available Languages

    static let availableLanguages: [String: String] = [
        "en": "English",
        "es": "Español",
        "pt": "Português",
        "fr": "Français",
        "de": "Deutsch",
        "it": "Italiano",
        "nl": "Nederlands",
        "ja": "日本語",
        "ko": "한국어"
    ]
}

// MARK: - Environment Key

private struct LanguageManagerKey: EnvironmentKey {
    static let defaultValue = LanguageManager.shared
}

extension EnvironmentValues {
    var languageManager: LanguageManager {
        get { self[LanguageManagerKey.self] }
        set { self[LanguageManagerKey.self] = newValue }
    }
}

// MARK: - View Extension for Easy Access

extension View {
    func languageManager(_ manager: LanguageManager) -> some View {
        environment(\.languageManager, manager)
    }
}
