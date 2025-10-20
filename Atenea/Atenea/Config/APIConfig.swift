//
//  APIConfig.swift
//  Atenea
//
//  Created by Claude on 10/15/25.
//

import Foundation

/// Configuración de API Keys
/// IMPORTANTE: Nunca subas este archivo a Git con tu API key real
struct APIConfig {

    // MARK: - Anthropic Claude API

    /// Tu API Key de Anthropic Claude
    /// Obtén tu key en: https://console.anthropic.com/settings/keys
    static let anthropicAPIKey = "sk-ant-PONDRA-TU-KEY-AQUI"

    /// URL base de la API de Anthropic
    static let anthropicBaseURL = "https://api.anthropic.com/v1"

    /// Versión de la API
    static let anthropicVersion = "2023-06-01"

    /// Modelo a usar
    static let defaultModel = "claude-sonnet-4-5-20250929"

    // MARK: - Validación

    /// Verifica si la API key está configurada correctamente
    static var isAPIKeyConfigured: Bool {
        return !anthropicAPIKey.isEmpty &&
               anthropicAPIKey != "sk-ant-PONDRA-TU-KEY-AQUI" &&
               anthropicAPIKey.hasPrefix("sk-ant-")
    }

    /// Mensaje de error si la API key no está configurada
    static var apiKeyErrorMessage: String {
        """
        ⚠️ API Key de Claude no configurada

        Por favor:
        1. Ve a https://console.anthropic.com/settings/keys
        2. Copia tu API key
        3. Pégala en APIConfig.swift en la línea:
           static let anthropicAPIKey = "TU-KEY-AQUI"
        """
    }
}
