import SwiftUI
import SwiftData

struct InspoCardView: View {
    let item: SavedItem
    
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        Group {
            // 1. Background Image
            if let data = item.screenshotData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
            } else {
                ZStack {
                    Color.gray.opacity(0.1)
                    Image(systemName: item.themeIcon)
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
            }
        }
        .overlay(alignment: .bottom) {
            // 2. Liquid Glass Footer
            HStack(spacing: 4) {
                if item.url?.scheme?.contains("https") == true {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
                
                Text(displayText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(Material.ultraThinMaterial)
            )
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.4)) // Increased opacity for visibility
            )
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
    
    var displayText: String {
        if let host = item.url?.host() {
             return host.replacingOccurrences(of: "www.", with: "")
        }
        return item.title
    }
}
    
    #Preview {
        let mockItem = SavedItem(
            url: URL(string: "https://apple.com"),
            type: .website,
            title: "Apple Design",
            summary: "Think Different"
        )
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            InspoCardView(item: mockItem)
                .frame(width: 170, height: 220)
        }
    }

