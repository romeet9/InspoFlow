import SwiftUI
import SwiftData
import PhotosUI

struct ScreenshotIngestionView: View {
    @Binding var isPresented: Bool
    var externalImage: UIImage?
    
    @Environment(\.modelContext) private var modelContext
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @StateObject private var aiService = RekognitionService()
    
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
    }
    
    func startAnalysis(image: UIImage) {
        Task {
            let result = await aiService.analyze(image: image)
            if let url = result.url {
                saveToModel(result: result)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                isPresented = false
            } else {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                // In a real app, show an alert error
                selectedImage = nil
            }
        }
    }
    
    func saveToModel(result: RekognitionService.AnalysisResult) {
        guard let selectedImage else { return }
        guard let urlString = result.url, !urlString.isEmpty else { return }
        
        var finalUrl = urlString
        if !finalUrl.lowercased().hasPrefix("http") {
            finalUrl = "https://\(finalUrl)"
        }
        
        let newItem = SavedItem(
            url: URL(string: finalUrl),
            type: result.category.lowercased().contains("app") ? .app : .website,
            screenshotData: selectedImage.jpegData(compressionQuality: 0.8),
            title: result.title,
            summary: result.summary
        )
        modelContext.insert(newItem)
    }
}

#Preview {
    ScreenshotIngestionView(isPresented: .constant(true))
}
