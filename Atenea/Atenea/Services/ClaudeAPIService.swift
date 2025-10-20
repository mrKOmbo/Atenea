//
//  ClaudeAPIService.swift
//  Atenea
//
//  Servicio para integración con Claude API
//

import Foundation
internal import Combine

class ClaudeAPIService: ObservableObject {

    // MARK: - Properties

    private let apiKey: String
    private let apiURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-5-20250929"  // Modelo actualizado

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Initialization

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - Public Methods

    /// Envía un mensaje a Claude y retorna la respuesta
    func sendMessage(_ message: String, conversationHistory: [ChatMessage] = []) async throws -> String {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        // Construir request
        guard let url = URL(string: apiURL) else {
            throw ClaudeAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        // Construir mensajes de la conversación
        var messages: [[String: Any]] = []

        // Agregar historial de conversación
        for msg in conversationHistory {
            messages.append([
                "role": msg.isUser ? "user" : "assistant",
                "content": msg.text
            ])
        }

        // Agregar mensaje actual
        messages.append([
            "role": "user",
            "content": message
        ])

        // Construir body del request
        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 2048,
            "messages": messages,
            "system": """
            Eres un asistente de viaje inteligente integrado en la app Atenea para el Mundial 2026.
            Tu trabajo es ayudar a los usuarios a descubrir lugares, restaurantes, atracciones y más.

            IMPORTANTE: Cuando menciones lugares específicos, SIEMPRE incluye las coordenadas en este formato:
            [LUGAR: Nombre del lugar | LAT: latitud | LON: longitud]

            Ejemplo de respuesta correcta:
            "Te recomiendo visitar estos lugares:

            🌮 [LUGAR: Tacos El Güero | LAT: 19.4326 | LON: -99.1332] - Los mejores tacos al pastor

            🏛️ [LUGAR: Museo Frida Kahlo | LAT: 19.3551 | LON: -99.1620] - Casa Azul imperdible"

            REGLAS:
            1. Usa coordenadas reales y precisas
            2. Incluye el formato [LUGAR:...] para CADA lugar que menciones
            3. Mantén la respuesta concisa pero informativa
            4. Usa emojis para hacerlo amigable
            5. Máximo 3-4 lugares por respuesta
            """
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Hacer request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Verificar respuesta HTTP
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // Intentar parsear error de la API
            if let errorResponse = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data) {
                throw ClaudeAPIError.apiError(errorResponse.error.message)
            }
            throw ClaudeAPIError.httpError(httpResponse.statusCode)
        }

        // Parsear respuesta
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        // Extraer texto de la respuesta
        guard let textContent = apiResponse.content.first(where: { $0.type == "text" }) else {
            throw ClaudeAPIError.noTextInResponse
        }

        return textContent.text
    }
}

// MARK: - API Models

struct ClaudeAPIResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ContentBlock]
    let model: String
    let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
    }
}

struct ContentBlock: Codable {
    let type: String
    let text: String
}

struct ClaudeErrorResponse: Codable {
    let error: ClaudeError
}

struct ClaudeError: Codable {
    let type: String
    let message: String
}

// MARK: - Errors

enum ClaudeAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case noTextInResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL de API inválida"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .httpError(let code):
            return "Error HTTP: \(code)"
        case .apiError(let message):
            return message
        case .noTextInResponse:
            return "No se recibió texto en la respuesta"
        }
    }
}
