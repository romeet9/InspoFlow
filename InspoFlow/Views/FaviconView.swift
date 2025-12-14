import SwiftUI

struct FaviconView: View {
    let url: URL?
    let size: CGFloat
    
    var body: some View {
        if let host = url?.host() {
            AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=64")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .scaleEffect(0.5)
                case .success(let image):
                    image
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .background(Color.white) // Start with white bg for transparency
                        .clipShape(Circle())
                case .failure:
                    FallbackIcon()
                @unknown default:
                    FallbackIcon()
                }
            }
            .frame(width: size, height: size)
            // Add a subtle shadow to make 2D icons pop a bit like 3D
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        } else {
            FallbackIcon()
        }
    }
    
    @ViewBuilder
    func FallbackIcon() -> some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.1))
                .font(.system(size: size * 0.5))
                .foregroundStyle(Color.blue)
        }
        .frame(width: size, height: size)
    }
}
