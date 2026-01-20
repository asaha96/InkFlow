import SwiftUI
import SwiftData

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
