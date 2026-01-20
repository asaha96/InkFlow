import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ImageLoader.self) private var imageLoader
    @Query(filter: #Predicate<Manga> { $0.isInLibrary }, sort: \Manga.dateAdded, order: .reverse) 
    private var libraryManga: [Manga]
    
    @State private var searchText = ""
    @State private var isGridView = true
    
    private var filteredManga: [Manga] {
        if searchText.isEmpty {
            return libraryManga
        }
        return libraryManga.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            Group {
                if libraryManga.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredManga) { manga in
                                NavigationLink(value: manga) {
                                    MangaCard(manga: manga)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText, prompt: "Search library")
            .navigationDestination(for: Manga.self) { manga in
                MangaDetailView(manga: manga)
            }
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Manga", systemImage: "books.vertical")
        } description: {
            Text("Browse the Discover tab to add manga to your library")
        } actions: {
            NavigationLink("Go to Discover") {
                DiscoveryView()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
