import Foundation
import SwiftSoup

/// Manganato source implementation
/// Parses content from manganato.com
final class ManganatoSource: MangaSource {
    let id = "manganato"
    let name = "Manganato"
    let baseURL = "https://manganato.com"
    let language = "en"
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
            "Referer": "https://manganato.com/"
        ]
        self.session = URLSession(configuration: config)
    }
    
    func fetchPopular(page: Int = 1) async throws -> [Manga] {
        let url = URL(string: "\(baseURL)/genre-all/\(page)?type=topview")!
        let html = try await fetchHTML(from: url)
        return try parseSearchResults(html: html)
    }
    
    func search(query: String, page: Int = 1) async throws -> [Manga] {
        let encodedQuery = query.replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? query
        let url = URL(string: "https://manganato.com/search/story/\(encodedQuery)?page=\(page)")!
        let html = try await fetchHTML(from: url)
        return try parseSearchResults(html: html)
    }
    
    func fetchChapters(for manga: Manga) async throws -> [Chapter] {
        guard let url = URL(string: manga.id) else {
            throw SourceError.invalidURL
        }
        let html = try await fetchHTML(from: url)
        return try parseChapters(html: html, mangaID: manga.id)
    }
    
    func fetchPages(for chapter: Chapter) async throws -> [Page] {
        guard let url = URL(string: chapter.url) else {
            throw SourceError.invalidURL
        }
        let html = try await fetchHTML(from: url)
        return try parsePages(html: html, chapterID: chapter.id)
    }
    
    func fetchMangaDetails(for manga: Manga) async throws -> Manga {
        guard let url = URL(string: manga.id) else {
            throw SourceError.invalidURL
        }
        let html = try await fetchHTML(from: url)
        return try parseMangaDetails(html: html, existingManga: manga)
    }
    
    // MARK: - Private Methods
    
    private func fetchHTML(from url: URL) async throws -> String {
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw SourceError.notFound
            }
            guard let html = String(data: data, encoding: .utf8) else {
                throw SourceError.parsingError("Failed to decode HTML")
            }
            return html
        } catch let error as SourceError {
            throw error
        } catch {
            throw SourceError.networkError(error)
        }
    }
    
    private func parseSearchResults(html: String) throws -> [Manga] {
        let doc = try SwiftSoup.parse(html)
        let items = try doc.select("div.search-story-item, div.content-genres-item")
        
        return try items.compactMap { item -> Manga? in
            guard let linkElement = try? item.select("a.item-img, a.a-h").first(),
                  let href = try? linkElement.attr("href"),
                  let imgElement = try? item.select("img").first(),
                  let imgSrc = try? imgElement.attr("src"),
                  let titleElement = try? item.select("a.item-title, h3 a").first(),
                  let title = try? titleElement.text() else {
                return nil
            }
            
            return Manga(
                id: href,
                title: title,
                coverURL: imgSrc,
                sourceID: self.id
            )
        }
    }
    
    private func parseChapters(html: String, mangaID: String) throws -> [Chapter] {
        let doc = try SwiftSoup.parse(html)
        let chapterElements = try doc.select("ul.row-content-chapter li, div.chapter-list div.row")
        
        return try chapterElements.enumerated().compactMap { index, element -> Chapter? in
            guard let linkElement = try? element.select("a").first(),
                  let href = try? linkElement.attr("href"),
                  let title = try? linkElement.text() else {
                return nil
            }
            
            // Extract chapter number from title
            let numberRegex = try? NSRegularExpression(pattern: "Chapter\\s*([\\d.]+)", options: .caseInsensitive)
            let range = NSRange(title.startIndex..., in: title)
            let chapterNumber: Double
            if let match = numberRegex?.firstMatch(in: title, range: range),
               let numberRange = Range(match.range(at: 1), in: title) {
                chapterNumber = Double(title[numberRange]) ?? Double(chapterElements.count - index)
            } else {
                chapterNumber = Double(chapterElements.count - index)
            }
            
            return Chapter(
                id: href,
                number: chapterNumber,
                title: title,
                url: href
            )
        }
    }
    
    private func parsePages(html: String, chapterID: String) throws -> [Page] {
        let doc = try SwiftSoup.parse(html)
        let imageElements = try doc.select("div.container-chapter-reader img")
        
        return try imageElements.enumerated().map { index, element in
            let src = try element.attr("src")
            return Page(index: index, imageURL: src, chapterID: chapterID)
        }
    }
    
    private func parseMangaDetails(html: String, existingManga: Manga) throws -> Manga {
        let doc = try SwiftSoup.parse(html)
        
        // Parse synopsis
        let synopsis = try doc.select("div.panel-story-info-description").first()?.text() ?? ""
        
        // Parse author
        let author = try doc.select("td:contains(Author) + td a, a.a-h[href*=author]").first()?.text() ?? ""
        
        // Parse status
        let status = try doc.select("td:contains(Status) + td").first()?.text() ?? "Ongoing"
        
        existingManga.synopsis = synopsis.replacingOccurrences(of: "Description :", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        existingManga.author = author
        existingManga.status = status
        
        return existingManga
    }
}
