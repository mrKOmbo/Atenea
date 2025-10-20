//
//  PostModels.swift
//  Atenea
//
//  Created for Community Posts Integration
//

import Foundation

// MARK: - Post Response
struct PostsResponse: Codable {
    let posts: [CommunityPost]
}

// MARK: - Community Post
struct CommunityPost: Codable, Identifiable {
    let id: Int
    let username: String
    let caption: String
    let url: String
    let keywords: String
    let likes: Int
    let date: String
    let processed: Bool

    // Computed properties for backwards compatibility
    var author: String { username }
    var title: String {
        // Usar primeras palabras del caption como título
        let words = caption.split(separator: " ").prefix(8).joined(separator: " ")
        return words + (caption.split(separator: " ").count > 8 ? "..." : "")
    }
    var content: String { caption }
    var image: String { url }
    var source: String { "Instagram" }

    var keywordArray: [String] {
        keywords.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    var formattedDate: String {
        let isoFormatter = ISO8601DateFormatter()
        guard let postDate = isoFormatter.date(from: date) else {
            return "Hace tiempo"
        }

        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: postDate, to: now)

        if let days = components.day, days > 0 {
            return "Hace \(days) día\(days == 1 ? "" : "s")"
        } else if let hours = components.hour, hours > 0 {
            return "Hace \(hours) hora\(hours == 1 ? "" : "s")"
        } else if let minutes = components.minute, minutes > 0 {
            return "Hace \(minutes) minuto\(minutes == 1 ? "" : "s")"
        } else {
            return "Justo ahora"
        }
    }
}
