import Foundation

/// Lightweight manga data for API responses (not persisted)
struct MangaDTO: Identifiable, Hashable {
    let id: String
    let title: String
    let coverURL: String
    let sourceID: String
    var synopsis: String
    var author: String
    var status: String
    
    init(
        id: String,
        title: String,
        coverURL: String,
        sourceID: String,
        synopsis: String = "",
        author: String = "",
        status: String = "Ongoing"
    ) {
        self.id = id
        self.title = title
        self.coverURL = coverURL
        self.sourceID = sourceID
        self.synopsis = synopsis
        self.author = author
        self.status = status
    }
    
    /// Convert to persisted Manga model
    func toManga() -> Manga {
        Manga(
            id: id,
            title: title,
            coverURL: coverURL,
            sourceID: sourceID,
            synopsis: synopsis,
            author: author,
            status: status
        )
    }
}

/// Lightweight chapter data for API responses (not persisted)
struct ChapterDTO: Identifiable, Hashable {
    let id: String
    let number: Double
    let title: String
    let url: String
    
    /// Convert to persisted Chapter model
    func toChapter() -> Chapter {
        Chapter(
            id: id,
            number: number,
            title: title,
            url: url
        )
    }
}
