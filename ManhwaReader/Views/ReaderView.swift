import SwiftUI
import SwiftData

struct ReaderView: View {
    let manga: Manga
    let chapters: [Chapter]
    let startingChapter: Chapter
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ImageLoader.self) private var imageLoader
    @Environment(HapticManager.self) private var hapticManager
    
    @AppStorage("ghostModeEnabled") private var ghostMode = false
    @AppStorage("webtoonModeEnabled") private var webtoonMode = true
    
    @State private var currentChapterIndex: Int = 0
    @State private var loadedChapters: [LoadedChapter] = []
    @State private var isLoading = false
    @State private var showControls = false
    @State private var scrollPosition: String?
    
    private let source = ManganatoSource()
    
    struct LoadedChapter: Identifiable {
        let id: String
        let chapter: Chapter
        let pages: [Page]
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Reader Content
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: webtoonMode ? 0 : 8) {
                            ForEach(loadedChapters) { loadedChapter in
                                chapterContent(loadedChapter, geometry: geometry)
                            }
                            
                            // Load more trigger
                            if !loadedChapters.isEmpty {
                                loadMoreTrigger
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .scrollPosition(id: $scrollPosition)
                }
                
                // Controls Overlay
                if showControls {
                    controlsOverlay
                }
                
                // Loading Overlay
                if isLoading && loadedChapters.isEmpty {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showControls.toggle()
                }
            }
        }
        .statusBarHidden(!showControls)
        .persistentSystemOverlays(showControls ? .automatic : .hidden)
        .task {
            await initialLoad()
        }
    }
    
    @ViewBuilder
    private func chapterContent(_ loadedChapter: LoadedChapter, geometry: GeometryProxy) -> some View {
        // Chapter Header
        Text("Chapter \(loadedChapter.chapter.number.chapterString)")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.8))
            .id("header-\(loadedChapter.id)")
        
        // Pages
        ForEach(loadedChapter.pages) { page in
            PageImageView(
                page: page,
                referer: URL(string: loadedChapter.chapter.url)?.host.map { "https://\($0)/" }
            )
            .id(page.id)
            .onAppear {
                handlePageAppear(page: page, chapter: loadedChapter)
            }
        }
        
        // Chapter End
        chapterEndView(loadedChapter)
    }
    
    private func chapterEndView(_ loadedChapter: LoadedChapter) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.green)
            
            Text("End of Chapter \(loadedChapter.chapter.number.chapterString)")
                .font(.headline)
                .foregroundStyle(.white)
            
            if let nextChapter = getNextChapter(after: loadedChapter.chapter) {
                Text("Scroll to continue to Chapter \(nextChapter.number.chapterString)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                Text("You've reached the latest chapter!")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(Color.black)
        .onAppear {
            hapticManager.chapterEnd()
            markChapterAsRead(loadedChapter.chapter)
        }
    }
    
    private var loadMoreTrigger: some View {
        Color.clear
            .frame(height: 100)
            .onAppear {
                Task {
                    await loadNextChapter()
                }
            }
    }
    
    private var controlsOverlay: some View {
        VStack {
            // Top Bar
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.black.opacity(0.6), in: Circle())
                }
                
                Spacer()
                
                if let current = loadedChapters.first(where: { loaded in
                    loaded.pages.contains { $0.id == scrollPosition }
                }) {
                    Text("Ch. \(current.chapter.number.chapterString)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.6), in: Capsule())
                }
                
                Spacer()
                
                if ghostMode {
                    Image(systemName: "eye.slash.fill")
                        .font(.title2)
                        .foregroundStyle(.purple)
                        .padding(12)
                        .background(.black.opacity(0.6), in: Circle())
                }
            }
            .padding()
            
            Spacer()
        }
    }
    
    private func initialLoad() async {
        guard let chapterIndex = chapters.firstIndex(where: { $0.id == startingChapter.id }) else {
            return
        }
        currentChapterIndex = chapterIndex
        await loadChapter(startingChapter)
    }
    
    private func loadChapter(_ chapter: Chapter) async {
        guard !loadedChapters.contains(where: { $0.id == chapter.id }) else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let pages = try await source.fetchPages(for: chapter)
            let loaded = LoadedChapter(id: chapter.id, chapter: chapter, pages: pages)
            
            await MainActor.run {
                loadedChapters.append(loaded)
                
                // Prefetch images
                let referer = URL(string: chapter.url)?.host.map { "https://\($0)/" }
                imageLoader.prefetch(urls: pages.map { $0.imageURL }, referer: referer)
            }
        } catch {
            print("Failed to load chapter: \(error)")
        }
    }
    
    private func loadNextChapter() async {
        guard let lastLoaded = loadedChapters.last,
              let nextChapter = getNextChapter(after: lastLoaded.chapter) else {
            return
        }
        
        await loadChapter(nextChapter)
    }
    
    private func getNextChapter(after chapter: Chapter) -> Chapter? {
        // Chapters are sorted by number descending, so "next" is actually at lower index
        let sortedChapters = chapters.sorted { $0.number < $1.number }
        guard let currentIndex = sortedChapters.firstIndex(where: { $0.id == chapter.id }),
              currentIndex + 1 < sortedChapters.count else {
            return nil
        }
        return sortedChapters[currentIndex + 1]
    }
    
    private func handlePageAppear(page: Page, chapter: LoadedChapter) {
        // Update scroll position for UI
        scrollPosition = page.id
        
        // If near end of chapter, start loading next
        if page.index >= chapter.pages.count - 3 {
            Task {
                await loadNextChapter()
            }
        }
    }
    
    private func markChapterAsRead(_ chapter: Chapter) {
        guard !ghostMode else { return }
        chapter.isRead = true
        chapter.dateRead = Date()
        manga.lastReadChapterID = chapter.id
        manga.lastReadDate = Date()
    }
}
