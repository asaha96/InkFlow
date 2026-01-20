import Foundation

/// Protocol defining the interface for manga sources
protocol MangaSource {
    var id: String { get }
    var name: String { get }
    var baseURL: String { get }
    var language: String { get }
    
    /// Fetch popular/trending manga
    func fetchPopular(page: Int) async throws -> [Manga]
    
    /// Search for manga by query
    func search(query: String, page: Int) async throws -> [Manga]
    
    /// Fetch chapters for a specific manga
    func fetchChapters(for manga: Manga) async throws -> [Chapter]
    
    /// Fetch pages (images) for a specific chapter
    func fetchPages(for chapter: Chapter) async throws -> [Page]
    
    /// Fetch manga details
    func fetchMangaDetails(for manga: Manga) async throws -> Manga
}

/// Errors that can occur during source operations
enum SourceError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case parsingError(String)
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        case .notFound:
            return "Content not found"
        }
    }
}
