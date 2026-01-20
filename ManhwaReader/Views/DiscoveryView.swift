import SwiftUI

struct DiscoveryView: View {
    @Environment(ImageLoader.self) private var imageLoader
    
    @State private var searchText = ""
    @State private var searchResults: [MangaDTO] = []
    @State private var popularManga: [MangaDTO] = []
    @State private var isLoading = false
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var selectedManga: MangaDTO?
    
    private let source = MangaDexSource()
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    if let error = errorMessage {
                        errorBanner(error)
                    }
                    
                    if !searchText.isEmpty {
                        searchResultsSection
                    } else {
                        popularSection
                    }
                }
                .padding()
            }
            .navigationTitle("Discover")
            .searchable(text: $searchText, prompt: "Search manga...")
            .onChange(of: searchText) { _, newValue in
                Task {
                    await performSearch(query: newValue)
                }
            }
            .task {
                await loadPopular()
            }
            .refreshable {
                await loadPopular()
            }
            .navigationDestination(item: $selectedManga) { manga in
                MangaDetailViewDTO(manga: manga)
            }
        }
    }
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Search Results")
                    .font(.title2.bold())
                
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if searchResults.isEmpty && !isSearching {
                ContentUnavailableView.search(text: searchText)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(searchResults) { manga in
                        Button {
                            selectedManga = manga
                        } label: {
                            MangaCardDTO(manga: manga)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Popular")
                    .font(.title2.bold())
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(popularManga) { manga in
                    Button {
                        selectedManga = manga
                    } label: {
                        MangaCardDTO(manga: manga)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.subheadline)
            Spacer()
            Button("Retry") {
                Task { await loadPopular() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
    
    private func loadPopular() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            popularManga = try await source.fetchPopular(page: 1)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        // Debounce
        try? await Task.sleep(for: .milliseconds(300))
        
        // Check if query is still the same
        guard query == searchText else { return }
        
        do {
            searchResults = try await source.search(query: query, page: 1)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSearching = false
    }
}

// MARK: - DTO-based Components

struct MangaCardDTO: View {
    let manga: MangaDTO
    @Environment(ImageLoader.self) private var imageLoader
    @State private var coverImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                if let image = coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                        }
                }
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.separator, lineWidth: 0.5)
            )
            
            Text(manga.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.primary)
        }
        .task {
            coverImage = await imageLoader.loadImage(from: manga.coverURL)
        }
    }
}

struct MangaDetailViewDTO: View {
    let manga: MangaDTO
    
    @Environment(\.modelContext) private var modelContext
    @Environment(ImageLoader.self) private var imageLoader
    @Environment(HapticManager.self) private var hapticManager
    
    @State private var chapters: [ChapterDTO] = []
    @State private var isLoadingChapters = false
    @State private var coverImage: UIImage?
    @State private var errorMessage: String?
    @State private var selectedChapter: ChapterDTO?
    @State private var mangaDetails: MangaDTO?
    
    private let source = MangaDexSource()
    
    private var displayManga: MangaDTO {
        mangaDetails ?? manga
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                
                if !displayManga.synopsis.isEmpty {
                    synopsisSection
                }
                
                chaptersSection
            }
            .padding()
        }
        .navigationTitle(manga.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDetails()
        }
        .fullScreenCover(item: $selectedChapter) { chapter in
            ReaderViewDTO(
                manga: displayManga,
                chapters: chapters,
                startingChapter: chapter
            )
        }
    }
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                if let image = coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .overlay { ProgressView() }
                }
            }
            .frame(width: 120, height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(displayManga.title)
                    .font(.headline)
                    .lineLimit(3)
                
                if !displayManga.author.isEmpty {
                    Label(displayManga.author, systemImage: "person.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Label(displayManga.status, systemImage: "clock.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("\(chapters.count) Chapters")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let firstChapter = chapters.last {
                    Button {
                        selectedChapter = firstChapter
                    } label: {
                        Label("Start Reading", systemImage: "play.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
            }
        }
    }
    
    private var synopsisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Synopsis")
                .font(.headline)
            
            Text(displayManga.synopsis)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var chaptersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Chapters")
                    .font(.headline)
                
                if isLoadingChapters {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            LazyVStack(spacing: 0) {
                ForEach(chapters.sorted(by: { $0.number > $1.number })) { chapter in
                    ChapterRowDTO(chapter: chapter) {
                        selectedChapter = chapter
                    }
                    Divider()
                }
            }
        }
    }
    
    private func loadDetails() async {
        coverImage = await imageLoader.loadImage(from: manga.coverURL)
        
        do {
            mangaDetails = try await source.fetchMangaDetails(mangaId: manga.id)
        } catch {
            // Not critical
        }
        
        isLoadingChapters = true
        do {
            chapters = try await source.fetchChapters(mangaId: manga.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingChapters = false
    }
}

struct ChapterRowDTO: View {
    let chapter: ChapterDTO
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chapter \(chapter.number.chapterString)")
                        .font(.headline)
                    
                    if !chapter.title.isEmpty && !chapter.title.starts(with: "Chapter") {
                        Text(chapter.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

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
