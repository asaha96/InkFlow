import Foundation

/// MangaDex API source implementation
/// Uses the public MangaDex API for manga data
final class MangaDexSource {
    let id = "mangadex"
    let name = "MangaDex"
    let baseURL = "https://api.mangadex.org"
    let language = "en"
    
    private let session: URLSession
    private let coverBaseURL = "https://uploads.mangadex.org/covers"
    
    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "ManhwaReader/1.0"
        ]
        self.session = URLSession(configuration: config)
    }
    
    func fetchPopular(page: Int = 1) async throws -> [MangaDTO] {
        let offset = (page - 1) * 20
        let url = URL(string: "\(baseURL)/manga?limit=20&offset=\(offset)&order[followedCount]=desc&includes[]=cover_art&contentRating[]=safe&contentRating[]=suggestive")!
        
        let data = try await fetchData(from: url)
        return try parseMangaList(data: data)
    }
    
    func search(query: String, page: Int = 1) async throws -> [MangaDTO] {
        let offset = (page - 1) * 20
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let url = URL(string: "\(baseURL)/manga?limit=20&offset=\(offset)&title=\(encodedQuery)&includes[]=cover_art&contentRating[]=safe&contentRating[]=suggestive")!
        
        let data = try await fetchData(from: url)
        return try parseMangaList(data: data)
    }
    
    func fetchChapters(mangaId: String) async throws -> [ChapterDTO] {
        var allChapters: [ChapterDTO] = []
        var offset = 0
        let limit = 100
        
        // MangaDex paginates chapters, fetch all
        while true {
            let url = URL(string: "\(baseURL)/manga/\(mangaId)/feed?limit=\(limit)&offset=\(offset)&translatedLanguage[]=en&order[chapter]=desc&includeEmptyPages=0")!
            
            let data = try await fetchData(from: url)
            let chapters = try parseChapterList(data: data)
            
            if chapters.isEmpty { break }
            allChapters.append(contentsOf: chapters)
            
            if chapters.count < limit { break }
            offset += limit
        }
        
        return allChapters
    }
    
    func fetchPages(chapterId: String) async throws -> [Page] {
        let url = URL(string: "\(baseURL)/at-home/server/\(chapterId)")!
        
        let data = try await fetchData(from: url)
        return try parsePages(data: data, chapterID: chapterId)
    }
    
    func fetchMangaDetails(mangaId: String) async throws -> MangaDTO {
        let url = URL(string: "\(baseURL)/manga/\(mangaId)?includes[]=author&includes[]=cover_art")!
        
        let data = try await fetchData(from: url)
        return try parseMangaDetails(data: data)
    }
    
    // MARK: - Private Methods
    
    private func fetchData(from url: URL) async throws -> Data {
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw SourceError.notFound
            }
            return data
        } catch let error as SourceError {
            throw error
        } catch {
            throw SourceError.networkError(error)
        }
    }
    
    private func parseMangaList(data: Data) throws -> [MangaDTO] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]] else {
            throw SourceError.parsingError("Invalid manga list response")
        }
        
        return dataArray.compactMap { item -> MangaDTO? in
            guard let id = item["id"] as? String,
                  let attributes = item["attributes"] as? [String: Any],
                  let titleObj = attributes["title"] as? [String: String] else {
                return nil
            }
            
            let title = titleObj["en"] ?? titleObj["ja"] ?? titleObj.values.first ?? "Unknown"
            
            // Get cover URL from relationships
            var coverURL = ""
            if let relationships = item["relationships"] as? [[String: Any]] {
                for rel in relationships {
                    if rel["type"] as? String == "cover_art",
                       let relAttributes = rel["attributes"] as? [String: Any],
                       let fileName = relAttributes["fileName"] as? String {
                        coverURL = "\(coverBaseURL)/\(id)/\(fileName).256.jpg"
                        break
                    }
                }
            }
            
            // Get description
            let descriptionObj = attributes["description"] as? [String: String]
            let synopsis = descriptionObj?["en"] ?? ""
            
            return MangaDTO(
                id: id,
                title: title,
                coverURL: coverURL,
                sourceID: self.id,
                synopsis: synopsis
            )
        }
    }
    
    private func parseChapterList(data: Data) throws -> [ChapterDTO] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]] else {
            throw SourceError.parsingError("Invalid chapter list response")
        }
        
        return dataArray.compactMap { item -> ChapterDTO? in
            guard let id = item["id"] as? String,
                  let attributes = item["attributes"] as? [String: Any] else {
                return nil
            }
            
            let chapterNum = attributes["chapter"] as? String ?? "0"
            let chapterNumber = Double(chapterNum) ?? 0
            let title = attributes["title"] as? String ?? "Chapter \(chapterNum)"
            
            return ChapterDTO(
                id: id,
                number: chapterNumber,
                title: title.isEmpty ? "Chapter \(chapterNum)" : title,
                url: "\(baseURL)/at-home/server/\(id)"
            )
        }
    }
    
    private func parsePages(data: Data, chapterID: String) throws -> [Page] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let baseUrl = json["baseUrl"] as? String,
              let chapter = json["chapter"] as? [String: Any],
              let hash = chapter["hash"] as? String,
              let pageFiles = chapter["data"] as? [String] else {
            throw SourceError.parsingError("Invalid pages response")
        }
        
        return pageFiles.enumerated().map { index, fileName in
            let imageURL = "\(baseUrl)/data/\(hash)/\(fileName)"
            return Page(index: index, imageURL: imageURL, chapterID: chapterID)
        }
    }
    
    private func parseMangaDetails(data: Data) throws -> MangaDTO {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any],
              let id = dataObj["id"] as? String,
              let attributes = dataObj["attributes"] as? [String: Any],
              let titleObj = attributes["title"] as? [String: String] else {
            throw SourceError.parsingError("Invalid manga details response")
        }
        
        let title = titleObj["en"] ?? titleObj["ja"] ?? titleObj.values.first ?? "Unknown"
        
        // Get author from relationships
        var author = ""
        var coverURL = ""
        if let relationships = dataObj["relationships"] as? [[String: Any]] {
            for rel in relationships {
                if rel["type"] as? String == "author",
                   let relAttributes = rel["attributes"] as? [String: Any],
                   let name = relAttributes["name"] as? String {
                    author = name
                }
                if rel["type"] as? String == "cover_art",
                   let relAttributes = rel["attributes"] as? [String: Any],
                   let fileName = relAttributes["fileName"] as? String {
                    coverURL = "\(coverBaseURL)/\(id)/\(fileName).256.jpg"
                }
            }
        }
        
        let status = (attributes["status"] as? String)?.capitalized ?? "Ongoing"
        let descriptionObj = attributes["description"] as? [String: String]
        let synopsis = descriptionObj?["en"] ?? ""
        
        return MangaDTO(
            id: id,
            title: title,
            coverURL: coverURL,
            sourceID: self.id,
            synopsis: synopsis,
            author: author,
            status: status
        )
    }
}

