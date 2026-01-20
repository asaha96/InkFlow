import SwiftUI

struct ReaderViewDTO: View {
    let manga: MangaDTO
    let chapters: [ChapterDTO]
    let startingChapter: ChapterDTO
    
    @Environment(\.dismiss) private var dismiss
    @Environment(ImageLoader.self) private var imageLoader
    @Environment(HapticManager.self) private var hapticManager
    
    @AppStorage("webtoonModeEnabled") private var webtoonMode = true
    
    @State private var loadedChapters: [LoadedChapterDTO] = []
    @State private var isLoading = false
    @State private var showControls = false
    @State private var scrollPosition: String?
    
    private let source = MangaDexSource()
    
    struct LoadedChapterDTO: Identifiable {
        let id: String
        let chapter: ChapterDTO
        let pages: [Page]
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: webtoonMode ? 0 : 8) {
                            ForEach(loadedChapters) { loadedChapter in
                                chapterContent(loadedChapter, geometry: geometry)
                            }
                            
                            if !loadedChapters.isEmpty {
                                loadMoreTrigger
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .scrollPosition(id: $scrollPosition)
                }
                
                if showControls {
                    controlsOverlay
                }
                
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
            await loadChapter(startingChapter)
        }
    }
    
    @ViewBuilder
    private func chapterContent(_ loadedChapter: LoadedChapterDTO, geometry: GeometryProxy) -> some View {
        Text("Chapter \(loadedChapter.chapter.number.chapterString)")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.8))
            .id("header-\(loadedChapter.id)")
        
        ForEach(loadedChapter.pages) { page in
            PageImageView(page: page, referer: "https://mangadex.org/")
                .id(page.id)
                .onAppear {
                    handlePageAppear(page: page, chapter: loadedChapter)
                }
        }
        
        chapterEndView(loadedChapter)
    }
    
    private func chapterEndView(_ loadedChapter: LoadedChapterDTO) -> some View {
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
                
                Color.clear.frame(width: 44, height: 44)
            }
            .padding()
            
            Spacer()
        }
    }
    
    private func loadChapter(_ chapter: ChapterDTO) async {
        guard !loadedChapters.contains(where: { $0.id == chapter.id }) else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let pages = try await source.fetchPages(chapterId: chapter.id)
            let loaded = LoadedChapterDTO(id: chapter.id, chapter: chapter, pages: pages)
            
            await MainActor.run {
                loadedChapters.append(loaded)
                imageLoader.prefetch(urls: pages.map { $0.imageURL }, referer: "https://mangadex.org/")
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
    
    private func getNextChapter(after chapter: ChapterDTO) -> ChapterDTO? {
        let sortedChapters = chapters.sorted { $0.number < $1.number }
        guard let currentIndex = sortedChapters.firstIndex(where: { $0.id == chapter.id }),
              currentIndex + 1 < sortedChapters.count else {
            return nil
        }
        return sortedChapters[currentIndex + 1]
    }
    
    private func handlePageAppear(page: Page, chapter: LoadedChapterDTO) {
        scrollPosition = page.id
        
        if page.index >= chapter.pages.count - 3 {
            Task {
                await loadNextChapter()
            }
        }
    }
}
