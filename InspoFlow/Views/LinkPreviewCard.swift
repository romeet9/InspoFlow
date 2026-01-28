import SwiftUI

struct LinkPreviewCard: View {
    let url: URL
    
    // Simple state for metadata (in a real app, use a metadata fetcher)
    var domain: String {
        url.host()?.replacingOccurrences(of: "www.", with: "") ?? "website"
    }
    
    var title: String {
        domain.components(separatedBy: ".").first?.capitalized ?? "Link"
    }
    
    var body: some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                // Icon / Favicon
                AsyncImage(url: URL(string: "https://icons.duckduckgo.com/ip3/\(domain).ico")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "safari.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 40, height: 40)
                .background(Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                
                // Metadata
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(domain)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
