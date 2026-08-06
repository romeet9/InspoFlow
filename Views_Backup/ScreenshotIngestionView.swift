import SwiftUI
import SwiftData
import PhotosUI

struct ScreenshotIngestionView: View {
    @Binding var isPresented: Bool
    var externalImage: UIImage?
    
    @Environment(\.modelContext) private var modelContext
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @StateObject private var aiService = HuggingFaceService()
    
    // UI Feedback
    @State private var duplicateAlertItem: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea() // Clean background
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Image Area
                    if let uiImage = selectedImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 400)
                            .modifier(AIGlowingBorder(isAnimating: aiService.isAnalyzing, cornerRadius: 16))
                            .shadow(radius: aiService.isAnalyzing ? 0 : 5)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                    } else {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            VStack(spacing: 16) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Color.accentColor)
                                Text("Tap to Select Screenshot")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    // Action Area
                    VStack(spacing: 16) {
                        if aiService.isAnalyzing {
                            AILoaderText()
                                .frame(height: 56)
                        } else if isUploading {
                             ProgressView("Uploading to Cloud...")
                                 .frame(height: 56)
                        } else {
                             Button {
                                 if let img = selectedImage {
                                     startAnalysis(image: img)
                                 }
                             } label: {
                                 Text("Analyze & Save")
                                     .font(.headline)
                                     .frame(maxWidth: .infinity)
                                     .frame(height: 56)
                             }
                             .buttonStyle(.borderedProminent)
                             .clipShape(RoundedRectangle(cornerRadius: 14))
                             .padding(.horizontal)
                             .shadow(radius: 2)
                             .disabled(selectedImage == nil)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Add Media")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
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

        }
        .alert("Already Saved", isPresented: Binding<Bool>(
            get: { duplicateAlertItem != nil },
            set: { if !$0 { duplicateAlertItem = nil } }
        )) {
            Button("OK") {
                duplicateAlertItem = nil
                isPresented = false // Dismiss sheet
            }
        } message: {
            Text("We found this exact link in your collection already.")
        }
    }

    
    func startAnalysis(image: UIImage) {
        Task {
            let result = await aiService.analyze(image: image)
            // Save regardless of URL presence (it might be just an image inspiration)
            saveToModel(result: result)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            isPresented = false
        }
    }
    
    // Cloud Upload State
    @State private var isUploading = false
    
    func saveToModel(result: HuggingFaceService.AnalysisResult) {
        guard let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        isUploading = true
        
        Task {
            do {
                // 1. Upload Image to Supabase Storage
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
                
                // Check for Duplicates (Pre-Save)
                if let finalUrl = finalUrl?.absoluteString {
                    let exists = try? await SupabaseDBService.shared.checkIfURLExists(url: finalUrl)
                    if exists == true {
                        await MainActor.run {
                            isUploading = false
                            duplicateAlertItem = finalUrl
                        }
                        return // Stop saving
                    }
                }
                
                let type: SavedItem.ItemType = result.category.lowercased().contains("app") ? .app : .website
                
                // Create Item (Optimistic Cloud Model)
                let newItem = SavedItem(
                    id: UUID(),
                    url: finalUrl,
                    timestamp: Date(),
                    type: type,
                    screenshotData: nil, // We rely on Supabase Storage now!
                    s3Url: publicUrl,
                    title: result.title,
                    summary: result.summary,
                    tags: (result.tags ?? []) + [result.category] // Merge custom tags with category
                )
                
                // 3. Save Metadata to Supabase DB
                try await SupabaseDBService.shared.saveItem(item: newItem, imageURL: publicUrl)
                
                // 4. Local SwiftData: REMOVED to prevent duplicates in hybrid views.
                // modelContext.insert(newItem)
                
                await MainActor.run {
                    isUploading = false
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    NotificationCenter.default.post(name: NSNotification.Name("ItemSaved"), object: nil) // Trigger Home Refresh
                    isPresented = false
                }
                
            } catch {
                print("❌ Cloud Save Failed: \(error)")
                await MainActor.run {
                    isUploading = false
                }
            }
        }
    }
}

#Preview {
    ScreenshotIngestionView(isPresented: .constant(true))
}
