# InkFlow 📖

A native iOS manhwa/webtoon reader built with Swift & SwiftUI. Ad-free, distraction-free reading with premium UX features.

## Features

| Feature | Description |
|---------|-------------|
| 🌊 **Infinite Stream** | Auto-load next chapters seamlessly while scrolling |
| 🎨 **Webtoon Mode** | Seamless image stitching for vertical comics |
| 👻 **Ghost Mode** | Incognito reading - no history saved |
| 📳 **Haptic Immersion** | Tactile feedback on chapter transitions |
| 💾 **Double-Tap Save** | Save any panel to Photos instantly |
| ⚡ **Smart Prefetch** | Pre-downloads upcoming chapters in background |

## Screenshots

*Coming soon*

## Requirements

- iOS 17.0+
- Xcode 15+
- Swift 5.9+

## Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/InkFlow.git
```

2. Open in Xcode
```bash
cd InkFlow
open ManhwaReader.xcodeproj
```

3. Select your Development Team in Signing & Capabilities

4. Build and run (⌘R)

### Sideloading with AltStore

1. Archive the app (Product → Archive)
2. Export as Ad Hoc IPA
3. Install via AltStore

## Architecture

- **SwiftUI** - Declarative UI framework
- **SwiftData** - Modern persistence
- **Swift Concurrency** - async/await for networking
- **SwiftSoup** - HTML parsing for content extraction

## Project Structure

```
ManhwaReader/
├── Models/          # SwiftData models
├── Sources/         # Content source plugins
├── Services/        # Image loading, caching, haptics
├── Views/           # SwiftUI views
└── Utilities/       # Extensions & constants
```

## Adding New Sources

Implement the `MangaSource` protocol:

```swift
protocol MangaSource {
    func fetchPopular(page: Int) async throws -> [Manga]
    func search(query: String, page: Int) async throws -> [Manga]
    func fetchChapters(for manga: Manga) async throws -> [Chapter]
    func fetchPages(for chapter: Chapter) async throws -> [Page]
}
```

## License

MIT License - feel free to use and modify!

---

*Built with ☕ and late nights*
