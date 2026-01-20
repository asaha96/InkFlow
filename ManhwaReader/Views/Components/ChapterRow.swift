import SwiftUI

struct ChapterRow: View {
    let chapter: Chapter
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chapter \(chapter.number.chapterString)")
                        .font(.headline)
                        .foregroundStyle(chapter.isRead ? .secondary : .primary)
                    
                    if !chapter.title.isEmpty && chapter.title != "Chapter \(chapter.number.chapterString)" {
                        Text(chapter.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if chapter.isRead {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                
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
