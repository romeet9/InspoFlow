import SwiftUI

struct DetailView: View {
    let item: SavedItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // 1. Hero Image (Centered Card)
                if let data = item.screenshotData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                } else {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 300)
                        .overlay(
                            Image(systemName: item.themeIcon)
                                .font(.system(size: 80))
                                .foregroundStyle(.secondary)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                }
                
                // 2. Header Info
                VStack(spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.caption)
                        if let host = item.url?.host() {
                            Text(host.replacingOccurrences(of: "www.", with: ""))
                        } else {
                             Text("Web")
                        }
                        
                        Text("•")
                        
                        Text(item.timestamp.formatted(date: .long, time: .omitted))
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                
                Divider()
                    .padding(.horizontal, 24)
                
                // 3. About Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(item.summary ?? "No description available.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 40)
                
                // 4. Action Buttons
                VStack(spacing: 16) {
                    // Open Link (Primary Blue)
                    if let urlString = item.url?.absoluteString, let url = URL(string: urlString) {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "safari.fill")
                                Text("Open Link")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                        }
                    }
                    
                    // Share (Secondary Gray)
                    if let url = item.url {
                        ShareLink(item: url) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(.systemGray6)) // Light gray
                            .foregroundStyle(.primary)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}
