import Foundation

/// Background service that pre-downloads upcoming chapters
actor ChapterPrefetcher {
    private var prefetchedChapters: Set<String> = []
    private var activeTasks: [String: Task<Void, Never>] = [:]
    private let source: MangaSource
    private let imageLoader: ImageLoader
    private let maxConcurrent = 2
    
    init(source: MangaSource, imageLoader: ImageLoader) {
        self.source = source
        self.imageLoader = imageLoader
    }
    
    /// Prefetch next N chapters starting from current
    func prefetchChapters(_ chapters: [Chapter], startingFrom currentIndex: Int, count: Int = 2) {
        let endIndex = min(currentIndex + count + 1, chapters.count)
        let chaptersToFetch = chapters[currentIndex..<endIndex]
        
        for chapter in chaptersToFetch {
            if prefetchedChapters.contains(chapter.id) || activeTasks[chapter.id] != nil {
                continue
            }
            
            let task = Task {
                await prefetchChapter(chapter)
            }
            activeTasks[chapter.id] = task
        }
    }
    
    private func prefetchChapter(_ chapter: Chapter) async {
        guard !prefetchedChapters.contains(chapter.id) else { return }
        
        do {
            let pages = try await source.fetchPages(for: chapter)
            let urls = pages.map { $0.imageURL }
            
            // Get referer from chapter URL
            let referer = URL(string: chapter.url)?.host.map { "https://\($0)/" }
            
            // Prefetch all images
            imageLoader.prefetch(urls: urls, referer: referer)
            
            prefetchedChapters.insert(chapter.id)
        } catch {
            print("Failed to prefetch chapter \(chapter.id): \(error)")
        }
        
        activeTasks.removeValue(forKey: chapter.id)
    }
    
    /// Check if a chapter has been prefetched
    func isPrefetched(_ chapterID: String) -> Bool {
        prefetchedChapters.contains(chapterID)
    }
    
    /// Clear prefetch cache
    func clearPrefetchCache() {
        prefetchedChapters.removeAll()
        for task in activeTasks.values {
            task.cancel()
        }
        activeTasks.removeAll()
    }
}
