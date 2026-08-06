import SwiftUI
import SwiftData

// MARK: - InspoCardView
struct InspoCardView: View {
    let item: SavedItem
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Full Bleed Artwork
            HeroImageView(item: item)
                .frame(maxWidth: .infinity)
                .aspectRatio(4/3, contentMode: .fit)
                .clipped()
                .background(Color(.systemGray6)) // Placeholder color
            
            // 2. Info Footer (Distinct Area)
            VStack(alignment: .leading, spacing: 4) {
                Text(websiteName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if let summary = item.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground)) // Slightly lighter than background
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Helpers
    private var websiteName: String {
        if let host = item.url?.host() {
            let cleanHost = host.replacingOccurrences(of: "www.", with: "")
            if let name = cleanHost.split(separator: ".").first {
                return String(name).capitalized
            }
            return cleanHost
        }
        return item.title.isEmpty ? "Inspiration" : item.title
    }
}

// MARK: - Subviews

private struct HeroImageView: View {
    let item: SavedItem
    @State private var image: UIImage? = nil
    @State private var isLoadingImage: Bool = true
    
    var body: some View {
        Color.clear
            .overlay {
                if let uiImage = image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .transition(.opacity.animation(.easeInOut))
                } else if isLoadingImage {
                    ZStack {
                        Color.gray.opacity(0.1)
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    FallbackIconView(item: item)
                }
            }
            .task(id: item.id) {
                await loadImage()
            }
    }
    
    private func loadImage() async {
        // 1. Check direct data
        if let data = item.screenshotData, let uiImage = await downsample(data: data) {
            await MainActor.run {
                self.image = uiImage
                self.isLoadingImage = false
            }
            return
        }
        
        // 2. Check S3 URL
        guard let s3UrlString = item.s3Url, let url = URL(string: s3UrlString) else {
            await MainActor.run { self.isLoadingImage = false }
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = await downsample(data: data) {
                await MainActor.run {
                    self.image = uiImage
                    self.isLoadingImage = false
                }
            } else {
                await MainActor.run { self.isLoadingImage = false }
            }
        } catch {
            await MainActor.run { self.isLoadingImage = false }
        }
    }
    
    // Downsampling optimization suggestion
    private func downsample(data: Data, to pointSize: CGSize = CGSize(width: 400, height: 300), scale: CGFloat = UIScreen.main.scale) async -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else { return nil }
        
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else { return nil }
        return UIImage(cgImage: downsampledImage)
    }
}

private struct FallbackIconView: View {
    let item: SavedItem
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
            Image(systemName: item.themeIcon)
                .font(.system(size: 40))
                .foregroundStyle(item.themeColor.opacity(0.5))
        }
    }
}
