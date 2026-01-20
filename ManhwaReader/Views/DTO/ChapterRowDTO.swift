import SwiftUI

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
