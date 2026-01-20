import Foundation
import SwiftData

@Model
final class Manga {
    @Attribute(.unique) var id: String
    var title: String
    var coverURL: String
    var sourceID: String
    var synopsis: String
    var author: String
    var status: String
    var lastReadChapterID: String?
    var lastReadDate: Date?
    var isInLibrary: Bool
    var dateAdded: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Chapter.manga)
    var chapters: [Chapter] = []
    
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
        self.isInLibrary = false
        self.dateAdded = Date()
    }
}
