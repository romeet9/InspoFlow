import SwiftUI
import SwiftData

// MARK: - iOS Rich Notification Style (Commented Out)
/*
/*
struct InspoCardViewNotification: View {
    let item: SavedItem
    @Environment(\.colorScheme) var colorScheme
    
    @State private var image: UIImage? = nil
    @State private var isLoadingImage: Bool = true
    
    var body: some View {
        VStack(spacing: 10) {
            // 1. Notification Header
            HStack(spacing: 6) {
                Image(systemName: "sparkles.rectangle.stack.fill") // App Icon Proxy
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(4)
                    .background(.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                
                Text("INSPIRATION")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("now")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14) // Header padding
            .padding(.top, 12)
            
            // 2. Notification Body (The Content)
            VStack(alignment: .leading, spacing: 8) {
                // Message Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(websiteName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(item.type.rawValue.lowercased())
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 14)
                
                // Media Attachment
                Color.clear
                    .aspectRatio(1.5, contentMode: .fit) // Media attachment aspect
                    .overlay {
                        if let uiImage = image {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if isLoadingImage {
                            ZStack {
                                Color.gray.opacity(0.05)
                                ProgressView()
                            }
                        } else {
                            fallbackView
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 10) // Inset media
                    .padding(.bottom, 10)
            }
        }
        .background(.regularMaterial) // The Glass Background
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous)) // Standard Notification Radius
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .task {
            await loadImage()
        }
    }
    
    // ... Helpers ...
    var websiteName: String {
        if let host = item.url?.host() {
            let cleanHost = host.replacingOccurrences(of: "www.", with: "")
            if let name = cleanHost.split(separator: ".").first {
                return String(name).capitalized
            }
            return cleanHost
        }
        return item.title.isEmpty ? "Inspiration" : item.title
    }
    
    var fallbackView: some View {
        ZStack {
            Color.gray.opacity(0.05)
            Image(systemName: item.themeIcon)
                .font(.system(size: 40))
                .foregroundStyle(Color.gray.opacity(0.3))
        }
    }
    
    private func loadImage() async {
        if let data = item.screenshotData, let uiImage = UIImage(data: data) {
            self.image = uiImage; self.isLoadingImage = false; return
        }
        guard let s3UrlString = item.s3Url, let url = URL(string: s3UrlString) else { self.isLoadingImage = false; return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) { self.image = uiImage; self.isLoadingImage = false } else { self.isLoadingImage = false }
        } catch { self.isLoadingImage = false }
    }
*/
}
*/

// MARK: - Apple Wallet / Pass Style (Commented Out)
/*
struct InspoCardViewAppleWallet: View {
    let item: SavedItem
    @Environment(\.colorScheme) var colorScheme
    
    @State private var image: UIImage? = nil
    @State private var isLoadingImage: Bool = true
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // 1. Card Background (The "Plastic" Surface)
            Color.clear
                .aspectRatio(1.58, contentMode: .fit) // Standard Credit Card Ratio
                .overlay {
                    if let uiImage = image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if isLoadingImage {
                        ZStack {
                            Color(hue: 0.6, saturation: 0.1, brightness: 0.2) // Dark Gray Placeholder
                            ProgressView()
                                .tint(.white)
                        }
                    } else {
                        fallbackView
                    }
                }
                .overlay(
                    // "Sheen" Gradient to simulate plastic/metal
                    LinearGradient(
                        colors: [
                            .white.opacity(0.15),
                            .white.opacity(0.0),
                            .black.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            
            // 2. Card Elements Overlay
            VStack {
                // Top Row: "Bank" Name + Contactless
                HStack(alignment: .top) {
                    Text(websiteName.uppercased())
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1) // Embossed
                    
                    Spacer()
                    
                    Image(systemName: "wave.3.right") // Contactless Symbol
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                }
                
                Spacer()
                
                // Middle Row: Chip (The Favicon)
                HStack {
                    Group {
                        if let url = item.url, let host = url.host() {
                           let cleanHost = host.replacingOccurrences(of: "www.", with: "")
                           LogoDevIconView(domain: cleanHost)
                       } else {
                           Image(systemName: item.themeIcon)
                               .resizable()
                               .padding(4)
                               .background(.white)
                       }
                    }
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(radius: 1)
                    
                    Spacer()
                }
                
                Spacer()
                
                // Bottom Row: "Card Number" + Network Logo
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ITEM TITLE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Text(item.title.isEmpty ? "INSPIRATION" : item.title.uppercased())
                            .font(.system(size: 12, weight: .medium, design: .monospaced)) // Credit Card Fontish
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Category "Badge" (Visa/Mastercard spot)
                    HStack(spacing: 4) {
                        Image(systemName: item.themeIcon)
                            .font(.system(size: 10, weight: .bold))
                        Text(item.type.rawValue.uppercased())
                            .font(.system(size: 10, weight: .heavy))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .padding(16)
        }
        .task {
            await loadImage()
        }
    }
    
    // ... Helpers ...
    var websiteName: String {
        if let host = item.url?.host() {
            let cleanHost = host.replacingOccurrences(of: "www.", with: "")
            if let name = cleanHost.split(separator: ".").first {
                return String(name).capitalized
            }
            return cleanHost
        }
        return item.title.isEmpty ? "Inspiration" : item.title
    }
    
    var fallbackView: some View {
        ZStack {
            Color(hue: 0.65, saturation: 0.4, brightness: 0.3)
            Image(systemName: item.themeIcon)
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.3))
        }
    }
    
    private func loadImage() async {
        if let data = item.screenshotData, let uiImage = UIImage(data: data) {
            self.image = uiImage; self.isLoadingImage = false; return
        }
        guard let s3UrlString = item.s3Url, let url = URL(string: s3UrlString) else { self.isLoadingImage = false; return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) { self.image = uiImage; self.isLoadingImage = false } else { self.isLoadingImage = false }
        } catch { self.isLoadingImage = false }
    }
}
*/

// MARK: - App Store "Today" Style (Commented Out)
/*
struct InspoCardViewAppStore: View {
    let item: SavedItem
    @Environment(\.colorScheme) var colorScheme
    
    @State private var image: UIImage? = nil
    @State private var isLoadingImage: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Hero Artwork
            GeometryReader { geo in
                Color.clear
                    .overlay {
                        if let uiImage = image {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        } else if isLoadingImage {
                            ZStack {
                                Color.gray.opacity(0.1)
                                ProgressView()
                            }
                        } else {
                            fallbackView
                        }
                    }
            }
            .aspectRatio(4/3, contentMode: .fit) // slightly landscape hero
            
            // 2. App Store Footer
            HStack(spacing: 12) {
                // Icon (App Icon style)
                Group {
                    if let url = item.url, let host = url.host() {
                        let cleanHost = host.replacingOccurrences(of: "www.", with: "")
                        LogoDevIconView(domain: cleanHost)
                    } else {
                        Image(systemName: item.themeIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22, height: 22)
                            .foregroundStyle(item.themeColor)
                    }
                }
                .frame(width: 44, height: 44)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black.opacity(0.05), lineWidth: 1))
                
                // Metadata
                VStack(alignment: .leading, spacing: 2) {
                    Text(websiteName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(item.type.rawValue.capitalized)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // "GET" / Action Button
                Text("OPEN")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        // Spring animation on tap (optional implicit feel)
        .contentShape(Rectangle())
        .task {
            await loadImage()
        }
    }
    
    // ... Helpers ...
    var websiteName: String {
        if let host = item.url?.host() {
            let cleanHost = host.replacingOccurrences(of: "www.", with: "")
            if let name = cleanHost.split(separator: ".").first {
                return String(name).capitalized
            }
            return cleanHost
        }
        return item.title.isEmpty ? "Inspiration" : item.title
    }
    
    var fallbackView: some View {
        ZStack {
            Color.gray.opacity(0.05)
            Image(systemName: item.themeIcon)
                .font(.system(size: 40))
                .foregroundStyle(Color.gray.opacity(0.3))
        }
    }
    
    private func loadImage() async {
        if let data = item.screenshotData, let uiImage = UIImage(data: data) {
            self.image = uiImage; self.isLoadingImage = false; return
        }
        guard let s3UrlString = item.s3Url, let url = URL(string: s3UrlString) else { self.isLoadingImage = false; return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) { self.image = uiImage; self.isLoadingImage = false } else { self.isLoadingImage = false }
        } catch { self.isLoadingImage = false }
    }
}
*/

// MARK: - Apple Music / Album Art Style (Commented Out)
/*
struct InspoCardViewAppleMusic: View {
    let item: SavedItem
    @Environment(\.colorScheme) var colorScheme
    
    @State private var image: UIImage? = nil
    @State private var isLoadingImage: Bool = true
    
    var body: some View {
        VStack(spacing: 12) {
            // 1. Artwork (The Album Cover)
            // distinct 1:1 square with deep shadow
            Color.clear
                .aspectRatio(1.0, contentMode: .fit)
                .overlay {
                    if let uiImage = image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if isLoadingImage {
                        ZStack {
                            Color.gray.opacity(0.05)
                            ProgressView()
                        }
                    } else {
                        fallbackView
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5) // "Album" Shadow
            
            // 2. Metadata (Usage like Song/Artist)
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(websiteName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(item.type.rawValue.capitalized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Small Action Icon (Context Menu style)
                Image(systemName: "ellipsis.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 20)) // Standard touch target size visual
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 2) // Slight inset alignment with shadow curve
        }
        .task {
            await loadImage()
        }
    }
    
    // ... Helpers ...
    var websiteName: String {
        if let host = item.url?.host() {
            let cleanHost = host.replacingOccurrences(of: "www.", with: "")
            if let name = cleanHost.split(separator: ".").first {
                return String(name).capitalized
            }
            return cleanHost
        }
        return item.title.isEmpty ? "Inspiration" : item.title
    }
    
    var fallbackView: some View {
        ZStack {
            Color.gray.opacity(0.05)
            Image(systemName: item.themeIcon)
                .font(.system(size: 40))
                .foregroundStyle(Color.gray.opacity(0.3))
        }
    }
    
    private func loadImage() async {
        if let data = item.screenshotData, let uiImage = UIImage(data: data) {
            self.image = uiImage; self.isLoadingImage = false; return
        }
        guard let s3UrlString = item.s3Url, let url = URL(string: s3UrlString) else { self.isLoadingImage = false; return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) { self.image = uiImage; self.isLoadingImage = false } else { self.isLoadingImage = false }
        } catch { self.isLoadingImage = false }
    }
}
*/

// MARK: - VisionOS Spatial Ornament Style (Replaced with App Store Style)
struct InspoCardView: View {
    let item: SavedItem
    @Environment(\.colorScheme) var colorScheme
    
    @State private var image: UIImage? = nil
    @State private var isLoadingImage: Bool = true
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Full Bleed Artwork
            Color.clear
                .aspectRatio(4/3, contentMode: .fit)
                .overlay {
                    if let url = item.url {
                        WebView(url: url, isInteractive: false, enableAutoScroll: true)
                    } else if let uiImage = image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if isLoadingImage {
                        ZStack {
                            Color.gray.opacity(0.1)
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        fallbackView
                    }
                }
                .clipped()
            
            // 2. Floating Glass Panel
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(websiteName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    if let summary = item.summary, !summary.isEmpty {
                        Text(summary)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Action Icon
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 28, height: 28)
                    .background(.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark) // Force Dark Glass
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(12) // Float off the edges
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .task {
            await loadImage()
        }
    }
    
    // ... Helpers ...
    var websiteName: String {
        if let host = item.url?.host() {
            let cleanHost = host.replacingOccurrences(of: "www.", with: "")
            if let name = cleanHost.split(separator: ".").first {
                return String(name).capitalized
            }
            return cleanHost
        }
        return item.title.isEmpty ? "Inspiration" : item.title
    }
    
    var fallbackView: some View {
        ZStack {
            Color.gray.opacity(0.1)
            Image(systemName: item.themeIcon)
                .font(.system(size: 40))
                .foregroundStyle(item.themeColor.opacity(0.5))
        }
    }
    
    private func loadImage() async {
        if let data = item.screenshotData, let uiImage = UIImage(data: data) {
            self.image = uiImage; self.isLoadingImage = false; return
        }
        guard let s3UrlString = item.s3Url, let url = URL(string: s3UrlString) else { self.isLoadingImage = false; return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) { self.image = uiImage; self.isLoadingImage = false } else { self.isLoadingImage = false }
        } catch { self.isLoadingImage = false }
    }
}

// MARK: - Apple News / Magazine Style (Commented Out)
/*
struct InspoCardViewAppleNews: View {
    let item: SavedItem
    @Environment(\.colorScheme) var colorScheme
    
    @State private var image: UIImage? = nil
    @State private var isLoadingImage: Bool = true
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 1. Artwork (Full Bleed)
            Color.clear
                .aspectRatio(1.0, contentMode: .fit)
                .overlay {
                    if let uiImage = image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if isLoadingImage {
                        ZStack {
                            Color.gray.opacity(0.1)
                            ProgressView()
                        }
                    } else {
                        fallbackView
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            
            // 2. Gradient Overlay (For Text Readability)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0.6), .transparent],
                        startPoint: .bottom,
                        endPoint: .center
                    )
                )
                .allowsHitTesting(false)
            
            // 3. Content Overlay (Title & Domain)
            VStack(alignment: .leading, spacing: 4) {
                Text(websiteName)
                    .font(.system(.headline, design: .default))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .shadow(radius: 2) // Enhance legibility
                
                HStack(spacing: 4) {
                     if let url = item.url, let host = url.host() {
                         let cleanHost = host.replacingOccurrences(of: "www.", with: "")
                         Text(cleanHost.uppercased())
                     } else {
                         Text("WEBSITE")
                     }
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))
            }
            .padding(16)
            
            // 4. Top Badge (Category Pill)
            VStack {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: item.themeIcon)
                            .font(.system(size: 10, weight: .semibold))
                        Text(item.type.rawValue.capitalized)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .foregroundStyle(.primary)
                    .background(.thinMaterial) // Frosted Glass Badge
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    Spacer()
                }
                Spacer()
            }
            .padding(12)
        }
        // Elevation
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        .task {
            await loadImage()
        }
    }
    
    // ... Helpers ...
    var websiteName: String {
        if let host = item.url?.host() {
            let cleanHost = host.replacingOccurrences(of: "www.", with: "")
            if let name = cleanHost.split(separator: ".").first {
                return String(name).capitalized
            }
            return cleanHost
        }
        return item.title.isEmpty ? "Inspiration" : item.title
    }
    
    var fallbackView: some View {
        ZStack {
            Color.gray.opacity(0.1)
            Image(systemName: item.themeIcon)
                .font(.system(size: 40))
                .foregroundStyle(item.themeColor.opacity(0.5))
        }
    }
    
    private func loadImage() async {
        if let data = item.screenshotData, let uiImage = UIImage(data: data) {
            self.image = uiImage; self.isLoadingImage = false; return
        }
        guard let s3UrlString = item.s3Url, let url = URL(string: s3UrlString) else { self.isLoadingImage = false; return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) { self.image = uiImage; self.isLoadingImage = false } else { self.isLoadingImage = false }
        } catch { self.isLoadingImage = false }
    }
}
*/

extension Color {
    static let transparent = Color.black.opacity(0)
}

// MARK: - Neo-Brutalist Design (Commented Out)
/*
struct InspoCardViewNeoBrutalist: View {
    let item: SavedItem
    @Environment(\.colorScheme) var colorScheme
    
    @State private var image: UIImage? = nil
    @State private var isLoadingImage: Bool = true
    
    // Brutalist Constants
    private let borderWidth: CGFloat = 2.0
    private let shadowOffset: CGFloat = 4.0
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Artwork (Raw Sharp Edges)
            Group {
                if let uiImage = image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if isLoadingImage {
                    ZStack {
                        Color(red: 0.88, green: 0.88, blue: 0.88) // Flat Gray
                        ProgressView()
                    }
                } else {
                    fallbackView
                }
            }
            .aspectRatio(1.0, contentMode: .fit)
            .clipped()
            .overlay(Rectangle().stroke(Color.black, lineWidth: borderWidth)) // Inner Image Border
            
            // 2. Brutalist Footer
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(websiteName.uppercased())
                    .font(.system(size: 16, weight: .black, design: .monospaced)) // BOLD MONO
                    .foregroundStyle(.black)
                    .lineLimit(1)
                
                HStack {
                    // Type Tag (Pill)
                    Text(item.type.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0, green: 1.0, blue: 0.62)) // Electric Green Tag
                        .overlay(Rectangle().stroke(Color.black, lineWidth: 1.5))
                    
                    Spacer()
                    
                    // Icon (Raw)
                    Image(systemName: item.themeIcon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                }
            }
            .padding(12)
            .background(Color.white)
        }
        .background(Color.white)
        .overlay(Rectangle().stroke(Color.black, lineWidth: borderWidth)) // Main Border
        .shadow(color: .black, radius: 0, x: shadowOffset, y: shadowOffset) // HARD SHADOW
        .task {
            await loadImage()
        }
    }
    
    // ... Helpers ...
    var websiteName: String {
        if let host = item.url?.host() {
            let cleanHost = host.replacingOccurrences(of: "www.", with: "")
            if let name = cleanHost.split(separator: ".").first {
                return String(name).capitalized
            }
            return cleanHost
        }
        return item.title.isEmpty ? "Inspiration" : item.title
    }
    
    var fallbackView: some View {
        ZStack {
            Color(red: 0.94, green: 0.94, blue: 0.94)
            Image(systemName: item.themeIcon)
                .font(.system(size: 32))
                .foregroundStyle(.black)
        }
    }
    
    private func loadImage() async {
        if let data = item.screenshotData, let uiImage = UIImage(data: data) {
            self.image = uiImage; self.isLoadingImage = false; return
        }
        guard let s3UrlString = item.s3Url, let url = URL(string: s3UrlString) else { self.isLoadingImage = false; return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) { self.image = uiImage; self.isLoadingImage = false } else { self.isLoadingImage = false }
        } catch { self.isLoadingImage = false }
    }
}
*/

// MARK: - Art Frame Concept (Commented Out)
/*
struct InspoCardViewArtFrame: View {
    let item: SavedItem
    @Environment(\.colorScheme) var colorScheme
    
    @State private var image: UIImage? = nil
    @State private var isLoadingImage: Bool = true
    
    var body: some View {
        VStack(spacing: 16) {
            // 1. Artwork (Framed)
            // Distinctly separate from edges, like art on a wall
            Group {
                if let uiImage = image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if isLoadingImage {
                    ZStack {
                        Color.gray.opacity(0.05)
                        ProgressView()
                    }
                } else {
                    fallbackView
                }
            }
            // Art Aspect Ratio (slightly taller than square, classic portrait) or Square
            .aspectRatio(1.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4) // "Hanging off wall" shadow
            
            // 2. Placard (Minimal Gallery Metadata)
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(websiteName)
                        .font(.system(size: 14, weight: .medium, design: .serif)) // Serif for "Art" feel
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(item.type.rawValue.uppercased())
                        .font(.system(size: 10, weight: .semibold, design: .default))
                        .foregroundStyle(.secondary)
                        .kerning(1.2) // Wide spacing for gallery look
                }
                Spacer()
                
                // Subtle Icon
                 Image(systemName: item.themeIcon)
                    .font(.system(size: 14))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 4)
        }
        .padding(20) // Large "Matte" Frame
        .background(Color.white) // Clean White Gallery Wall
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous)) // Sharp Art Card corners (almost square)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1) // Card thickness
        .task {
            await loadImage()
        }
    }
    
    // ... Helpers ...
    var websiteName: String {
        if let host = item.url?.host() {
            let cleanHost = host.replacingOccurrences(of: "www.", with: "")
            if let name = cleanHost.split(separator: ".").first {
                return String(name).capitalized
            }
            return cleanHost
        }
        return item.title.isEmpty ? "Inspiration" : item.title
    }
    
    var fallbackView: some View {
        ZStack {
            Color.gray.opacity(0.05)
            Image(systemName: item.themeIcon)
                .font(.system(size: 32))
                .foregroundStyle(Color.gray.opacity(0.3))
        }
    }
    
    private func loadImage() async {
        if let data = item.screenshotData, let uiImage = UIImage(data: data) {
            self.image = uiImage; self.isLoadingImage = false; return
        }
        guard let s3UrlString = item.s3Url, let url = URL(string: s3UrlString) else { self.isLoadingImage = false; return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) { self.image = uiImage; self.isLoadingImage = false } else { self.isLoadingImage = false }
        } catch { self.isLoadingImage = false }
    }
}
*/

// MARK: - Widget Style (Commented Out)
/*
struct InspoCardViewWidgetStyle: View {
    let item: SavedItem
    @Environment(\.colorScheme) var colorScheme
    
    @State private var image: UIImage? = nil
    @State private var isLoadingImage: Bool = true
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // ------------------------------------------------------------
            // 1. Artwork (Full Bleed)
            // ------------------------------------------------------------
            Color.clear
                .aspectRatio(1.0, contentMode: .fit)
                .overlay {
                    if let uiImage = image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if isLoadingImage {
                        ZStack {
                            Color.gray.opacity(0.1)
                            ProgressView()
                        }
                    } else {
                        fallbackView
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            
            // ------------------------------------------------------------
            // 2. Native Glass Footer (Widget Style)
            // ------------------------------------------------------------
            HStack(spacing: 12) {
                // Icon (Native Squircle)
                Group {
                    if let url = item.url, let host = url.host() {
                        let cleanHost = host.replacingOccurrences(of: "www.", with: "")
                        LogoDevIconView(domain: cleanHost)
                    } else {
                        Image(systemName: item.themeIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundStyle(item.themeColor)
                    }
                }
                .frame(width: 40, height: 40)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                // Text Stack
                VStack(alignment: .leading, spacing: 2) {
                    Text(websiteName)
                        .font(.headline) // Standard Apple Headline
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(item.type.rawValue.capitalized)
                        .font(.caption) // Standard Apple Caption
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Action Icon (Chevron)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(.regularMaterial) // Native Apple Material
            .clipShape(
                .rect(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 20,
                    bottomTrailingRadius: 20,
                    topTrailingRadius: 0
                )
            )
            // Separator Line Logic (Optional, native Divider look)
            .overlay(alignment: .top) {
                Divider().background(Color.gray.opacity(0.2))
            }
        }
        // Container Shadow
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
        .task {
            await loadImage()
        }
    }
    
    // ... Helpers ...
    var websiteName: String {
        if let host = item.url?.host() {
            let cleanHost = host.replacingOccurrences(of: "www.", with: "")
            if let name = cleanHost.split(separator: ".").first {
                return String(name).capitalized
            }
            return cleanHost
        }
        return item.title.isEmpty ? "Inspiration" : item.title
    }
    
    var fallbackView: some View {
        ZStack {
            Color.gray.opacity(0.1)
            Image(systemName: item.themeIcon)
                .font(.system(size: 40))
                .foregroundStyle(item.themeColor.opacity(0.5))
        }
    }
    
    private func loadImage() async {
        // Priority 1: Local Data
        if let data = item.screenshotData, let uiImage = UIImage(data: data) {
            self.image = uiImage
            self.isLoadingImage = false
            return
        }
        
        // Priority 2: Remote URL
        guard let s3UrlString = item.s3Url, let url = URL(string: s3UrlString) else {
            self.isLoadingImage = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                self.image = uiImage
                self.isLoadingImage = false
            } else {
                self.isLoadingImage = false
            }
        } catch {
            self.isLoadingImage = false
        }
    }
}
*/



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
            .frame(width: 160)
            .padding()
    }
}
