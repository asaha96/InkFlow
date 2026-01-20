import Foundation

struct Page: Identifiable, Equatable, Hashable {
    let id: String
    let index: Int
    let imageURL: String
    let chapterID: String
    
    init(index: Int, imageURL: String, chapterID: String) {
        self.id = "\(chapterID)-\(index)"
        self.index = index
        self.imageURL = imageURL
        self.chapterID = chapterID
    }
}
