import SwiftUI

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
