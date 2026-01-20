import Foundation
import SwiftData

@Model
final class Chapter {
    @Attribute(.unique) var id: String
    var number: Double
    var title: String
    var url: String
    var isRead: Bool
    var dateRead: Date?
    var manga: Manga?
    
    @Transient
    var pages: [Page] = []
    
    init(
        id: String,
        number: Double,
        title: String,
        url: String
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.url = url
        self.isRead = false
    }
}
