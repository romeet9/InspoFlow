import SwiftUI

// MARK: - AI Glowing Border Modifier
struct AIGlowingBorder: ViewModifier {
    var isAnimating: Bool
    var cornerRadius: CGFloat = 16
    
    @State private var breathe = false
    
    // Cyan/Blue mixed with Soft Gold/Yellow
    private let gradientColors: [Color] = [
        Color.cyan,
        Color.blue.opacity(0.8),
        Color(red: 1.0, green: 0.84, blue: 0.0), // Soft Gold
        Color.yellow.opacity(0.8)
    ]

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .background(
                ZStack {
                    // Ambient Static Glow
                    if isAnimating {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: gradientColors),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blur(radius: 20)
                            .scaleEffect(1.05)
                            .opacity(0.5)
                            .transition(.opacity.animation(.easeInOut(duration: 0.8)))
                    }
                }
            )
    }
}

// MARK: - Animated Text Component
struct AILoaderText: View {
    let text: String = "Generating..."
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<text.count, id: \.self) { index in
                Text(String(text[text.index(text.startIndex, offsetBy: index)]))
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .opacity(isAnimating ? 1 : 0.4)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever()
                        .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
