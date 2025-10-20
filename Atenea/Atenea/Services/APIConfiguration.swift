//
//  APIConfiguration.swift
//  Atenea
//
//  Configuración de API keys
//

import Foundation

class APIConfiguration {

    static let shared = APIConfiguration()

    private init() {}

    // MARK: - Claude API Key

    var claudeAPIKey: String {
        get {
            // Primero intenta leer de UserDefaults
            if let savedKey = UserDefaults.standard.string(forKey: "claudeAPIKey"), !savedKey.isEmpty {
                return savedKey
            }

            // Si no hay clave guardada, intenta leer de Info.plist
            if let apiKey = Bundle.main.object(forInfoDictionaryKey: "CLAUDE_API_KEY") as? String, !apiKey.isEmpty {
                return apiKey
            }

            // Retornar vacío si no hay clave configurada
            return ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "claudeAPIKey")
        }
    }

    var hasClaudeAPIKey: Bool {
        return !claudeAPIKey.isEmpty
    }
}
