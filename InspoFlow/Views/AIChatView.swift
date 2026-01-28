import SwiftUI

struct AIChatView: View {
    @StateObject private var hfService = HuggingFaceService()
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "Hello! Describe your project or problem, and I'll recommend some websites or design tools.", isUser: false)
    ]
    @FocusState private var isFocused: Bool
    
    // Background Animation State
    @State private var animateGradient = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Live Ambient Background
                AmbientBackground(animate: $animateGradient)
                    .ignoresSafeArea()
                    .onAppear { animateGradient = true }
                
                VStack(spacing: 0) {
                    // Chats
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(messages) { msg in
                                    ChatBubble(message: msg)
                                }
                                
                                if hfService.isAnalyzing {
                                    HStack {
                                        TypingIndicator()
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .id("typing")
                                }
                                
                                // Bottom Spacer to lift content above input bar
                                Color.clear.frame(height: 60)
                            }
                            .padding(.vertical)
                        }
                        .scrollIndicators(.hidden)
                        .onChange(of: messages.count) {
                            withAnimation {
                                proxy.scrollTo(messages.last?.id, anchor: .bottom)
                            }
                        }
                        .onChange(of: hfService.isAnalyzing) { oldValue, newValue in
                             if newValue {
                                 withAnimation {
                                     proxy.scrollTo("typing", anchor: .bottom)
                                 }
                             }
                        }
                    }
                    
                    // Input Bar
                    VStack(spacing: 0) {
                        Divider()
                            .overlay(.white.opacity(0.1))
                            
                        HStack(alignment: .bottom, spacing: 12) {
                            TextField("Ask for recommendations...", text: $messageText, axis: .vertical)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                                )
                                .focused($isFocused)
                                .lineLimit(1...5)
                            
                            Button {
                                sendMessage()
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 34))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, messageText.isEmpty ? .white.opacity(0.1) : .blue)
                            }
                            .disabled(messageText.isEmpty || hfService.isAnalyzing)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial) // Glass Input Bar
                    }
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar) // Transparent Navbar
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let userMsg = messageText
        messageText = ""
        isFocused = false
        
        let userMessage = ChatMessage(text: userMsg, isUser: true)
        messages.append(userMessage)
        
        Task {
            let response = await hfService.chat(message: userMsg)
            await MainActor.run {
                let aiMessage = ChatMessage(text: response, isUser: false)
                messages.append(aiMessage)
            }
        }
    }
}

// MARK: - Models & Components

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp = Date()
    
    // Extract all URLs (Unique)
    var links: [URL] {
        let types: NSTextCheckingResult.CheckingType = .link
        guard let detector = try? NSDataDetector(types: types.rawValue) else { return [] }
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        let urls = matches.compactMap { $0.url }
        return Array(Set(urls)).sorted { $0.absoluteString < $1.absoluteString }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 12) {
            // ... (keep existing bubble header/text logic)
            HStack(alignment: .bottom, spacing: 8) {
                if message.isUser {
                    Spacer()
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white) // Keep Icon White for contrast on gradient
                        .frame(width: 30, height: 30)
                        .background(
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(Circle())
                        // Shadow usually fine, but can adapt if needed
                        .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                
                if !message.links.isEmpty && !message.isUser {
                    // If we have links from AI, hide the text bubble to keep it clean (as requested)
                    EmptyView()
                } else {
                    Text(.init(message.text))
                        .font(.system(size: 16, design: .default))
                        .foregroundStyle(message.isUser ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background {
                            if message.isUser {
                                Color.blue
                            } else {
                                Rectangle().fill(.ultraThinMaterial)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(message.isUser ? Color.white.opacity(0) : Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                
                if !message.isUser {
                    Spacer()
                }
            }
            
            // Link Previews (Only for AI) - Render ALL links
            if !message.isUser && !message.links.isEmpty {
                VStack(spacing: 12) {
                    ForEach(message.links, id: \.self) { url in
                        LinkPreviewCard(url: url)
                    }
                }
                .padding(.leading, 38) // Align with text
                .padding(.trailing, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal)
    }
}

struct TypingIndicator: View {
    @State private var numberOfDots = 0
    
    var body: some View {
        HStack(spacing: 4) {
             ForEach(0..<3) { _ in
                 Circle()
                     .fill(Color.secondary.opacity(0.5))
                     .frame(width: 6, height: 6)
             }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
             RoundedRectangle(cornerRadius: 20)
                 .stroke(.white.opacity(0.2), lineWidth: 0.5)
        )
    }
}

// MARK: - Animated Background
struct AmbientBackground: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var animate: Bool
    
    var body: some View {
        ZStack {
            // Adaptive Base Color
            (colorScheme == .dark ? Color.black : Color(uiColor: .systemBackground))
            
            // Abstract Blobs
            Group {
                // Blob 1
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: animate ? -100 : 100, y: animate ? -150 : 0)
                    .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animate)
                
                // Blob 2
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 350, height: 350)
                    .blur(radius: 60)
                    .offset(x: animate ? 150 : -50, y: animate ? 200 : -100)
                    .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: animate)
                    
                // Blob 3
                Circle()
                    .fill(Color.cyan.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: animate ? -50 : 150, y: animate ? 100 : 250)
                    .animation(.easeInOut(duration: 11).repeatForever(autoreverses: true), value: animate)
            }
        }
    }
}

#Preview {
    AIChatView()
}
