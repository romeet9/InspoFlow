import SwiftUI
import SwiftData
import PhotosUI

struct ScreenshotIngestionView: View {
    @Binding var isPresented: Bool
    var externalImage: UIImage?
    
    @Environment(\.modelContext) private var modelContext
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @StateObject private var aiService = NvidiaAIService()
    
    // UI Feedback
    @State private var duplicateAlertItem: String?
    @State private var isUploading = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Image Selection Area
                    ZStack {
                        if let uiImage = selectedImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 500)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color(.separator), lineWidth: 1)
                                )
                        } else {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                VStack(spacing: 16) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 48))
                                        .foregroundStyle(Color.accentColor)
                                    
                                    VStack(spacing: 4) {
                                        Text("Select Screenshot")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("Tap to browse your library")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                                        .foregroundStyle(Color.accentColor.opacity(0.3))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // MARK: - Status & Info
                    if aiService.isAnalyzing || isUploading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.large)
                            Text(statusText)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    } else if selectedImage != nil {
                        Text("Ready to Analyze")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Inspiration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Analyze & Save") {
                        if let img = selectedImage {
                            startAnalysis(image: img)
                        }
                    }
                    .disabled(selectedImage == nil || aiService.isAnalyzing || isUploading)
                    .fontWeight(.semibold)
                }
            }
            .interactiveDismissDisabled(aiService.isAnalyzing || isUploading)
            .onAppear {
                if let external = externalImage {
                    selectedImage = external
                }
            }
            .onChange(of: selectedItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = image
                        }
                    }
                }
            }
            .alert("Duplicate Link", isPresented: Binding<Bool>(
                get: { duplicateAlertItem != nil },
                set: { if !$0 { duplicateAlertItem = nil } }
            )) {
                Button("OK") {
                    duplicateAlertItem = nil
                    isPresented = false
                }
            } message: {
                Text("This URL is already in your collection.")
            }
        }
    }
    
    // MARK: - Helpers
    
    private var statusText: String {
        if isUploading { return "Uploading..." }
        if aiService.isAnalyzing { return "Analyzing with AI..." }
        return ""
    }
    
    func startAnalysis(image: UIImage) {
        Task {
            let result = await aiService.analyze(image: image)
            saveToModel(result: result)
        }
    }
    
    func saveToModel(result: NvidiaAIService.AnalysisResult) {
        guard let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        isUploading = true
        
        Task {
            do {
                // 1. Upload Image
                let filename = "\(UUID().uuidString).jpg"
                let publicUrl = try await SupabaseStorageService.shared.uploadImage(data: imageData, filename: filename)
                
                // 2. Prepare Data
                var finalUrl: URL? = nil
                if let urlString = result.url, !urlString.isEmpty {
                    var cleanUrl = urlString
                    if !cleanUrl.lowercased().hasPrefix("http") {
                        cleanUrl = "https://\(cleanUrl)"
                    }
                    finalUrl = URL(string: cleanUrl)
                }
                
                // Check Duplicates
                if let finalString = finalUrl?.absoluteString {
                    let exists = try? await SupabaseDBService.shared.checkIfURLExists(url: finalString)
                    if exists == true {
                        await MainActor.run {
                            isUploading = false
                            duplicateAlertItem = finalString
                        }
                        return
                    }
                }
                
                let type: SavedItem.ItemType = result.category.lowercased().contains("app") ? .app : .website
                
                let newItem = SavedItem(
                    id: UUID(),
                    url: finalUrl,
                    timestamp: Date(),
                    type: type,
                    screenshotData: nil,
                    s3Url: publicUrl,
                    title: result.title,
                    summary: result.summary,
                    tags: (result.tags ?? []) + [result.category]
                )
                
                // 3. Save
                try await SupabaseDBService.shared.saveItem(item: newItem, imageURL: publicUrl)
                
                await MainActor.run {
                    isUploading = false
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    NotificationCenter.default.post(name: NSNotification.Name("ItemSaved"), object: nil)
                    isPresented = false
                }
                
            } catch {
                print("❌ Cloud Save Failed: \(error)")
                await MainActor.run { isUploading = false }
            }
        }
    }
}

#Preview {
    ScreenshotIngestionView(isPresented: .constant(true))
}
