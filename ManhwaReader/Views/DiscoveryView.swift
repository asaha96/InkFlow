import SwiftUI
import SwiftData

struct DiscoveryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ImageLoader.self) private var imageLoader
    
    @State private var searchText = ""
    @State private var searchResults: [Manga] = []
    @State private var popularManga: [Manga] = []
    @State private var isLoading = false
    @State private var isSearching = false
    @State private var errorMessage: String?
    
    private let source = ManganatoSource()
    
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
            .navigationDestination(for: Manga.self) { manga in
                MangaDetailView(manga: manga)
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
                        NavigationLink(value: manga) {
                            MangaCard(manga: manga)
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
                    NavigationLink(value: manga) {
                        MangaCard(manga: manga)
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
