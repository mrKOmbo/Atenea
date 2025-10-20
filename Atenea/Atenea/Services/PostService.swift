//
//  PostService.swift
//  Atenea
//
//  Service for fetching community posts from API
//

import Foundation
internal import Combine

@MainActor
class PostService: ObservableObject {
    @Published var posts: [CommunityPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let baseURL = "http://152.53.54.76:9000/api"

    // Singleton para uso compartido
    static let shared = PostService()

    private init() {}

    // MARK: - Fetch Posts
    func fetchPosts() async {
        isLoading = true
        errorMessage = nil

        // Limpiar posts anteriores para forzar recarga
        self.posts = []

        // Intentar cargar todos los posts con diferentes estrategias
        await fetchAllPosts()

        isLoading = false
    }

    // MARK: - Fetch All Posts
    private func fetchAllPosts() async {
        var allPosts: [CommunityPost] = []
        var page = 1
        var hasMorePages = true

        print("🔄 Starting to load ALL Instagram posts...")

        while hasMorePages {
            // Intentar cargar todos los posts - primero sin límite, luego con paginación si es necesario
            let urlString: String
            if page == 1 {
                // Primera petición: sin límite para obtener todos los posts
                urlString = "\(baseURL)/posts/instagram"
            } else {
                // Peticiones siguientes con paginación (por si el endpoint la soporta)
                urlString = "\(baseURL)/posts/instagram?page=\(page)&limit=100"
            }

            guard let url = URL(string: urlString) else {
                errorMessage = "URL inválida"
                return
            }

            print("🌐 Request #\(page): \(url.absoluteString)")

            do {
                let (data, response) = try await URLSession.shared.data(from: url)

                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = "Respuesta del servidor inválida"
                    return
                }

                print("📡 Status Code: \(httpResponse.statusCode)")

                if page == 1 {
                    print("📋 Headers: \(httpResponse.allHeaderFields)")
                }

                if httpResponse.statusCode == 200 {
                    // Log del JSON raw recibido
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📦 JSON received from endpoint (page \(page)):")
                        print(jsonString)
                    }

                    let decoder = JSONDecoder()
                    let postsResponse = try decoder.decode(PostsResponse.self, from: data)

                    if postsResponse.posts.isEmpty {
                        print("⚠️ No more posts on page \(page)")
                        hasMorePages = false
                    } else {
                        allPosts.append(contentsOf: postsResponse.posts)
                        print("✅ Page \(page): Loaded \(postsResponse.posts.count) posts (Total accumulated: \(allPosts.count))")

                        // Si es la primera petición sin parámetros, ya tenemos todos los posts
                        if page == 1 && !urlString.contains("page=") {
                            print("📦 All posts loaded in single request")
                            hasMorePages = false
                        } else if postsResponse.posts.count < 100 {
                            // Si obtuvimos menos de 100, probablemente no hay más páginas
                            print("📦 Received less than 100 posts, assuming no more pages")
                            hasMorePages = false
                        } else {
                            page += 1
                        }
                    }
                } else {
                    errorMessage = "Server error: \(httpResponse.statusCode)"
                    print("⚠️ Server error: \(httpResponse.statusCode)")

                    // Log de la respuesta de error
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("⚠️ Server response: \(errorString)")
                    }
                    hasMorePages = false
                }
            } catch {
                errorMessage = "Error loading posts: \(error.localizedDescription)"
                print("❌ Error loading posts: \(error)")
                print("❌ Error details: \(error)")
                hasMorePages = false
            }
        }

        // Ordenar posts por fecha (más recientes primero)
        let sortedPosts = allPosts.sorted { post1, post2 in
            let formatter = ISO8601DateFormatter()
            let date1 = formatter.date(from: post1.date) ?? Date.distantPast
            let date2 = formatter.date(from: post2.date) ?? Date.distantPast
            return date1 > date2
        }

        // Actualizar la lista completa de posts
        self.posts = sortedPosts

        print("🎉 LOAD COMPLETE: Total of \(sortedPosts.count) posts loaded (sorted by date, newest first)")
        print("📝 Posts summary (ordered by newest first):")
        for (index, post) in sortedPosts.enumerated() {
            print("  Post #\(index + 1):")
            print("    - ID: \(post.id)")
            print("    - Username: \(post.username)")
            print("    - Caption: \(post.caption.prefix(100))...")
            print("    - Likes: \(post.likes)")
            print("    - Keywords: \(post.keywords)")
            print("    - Image URL: \(post.url)")
            print("    - Date: \(post.date)")
            print("    - Processed: \(post.processed)")
        }
    }

    // MARK: - Refresh Posts
    func refreshPosts() async {
        await fetchPosts()
    }
}
