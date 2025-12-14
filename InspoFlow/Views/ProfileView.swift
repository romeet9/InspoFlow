import SwiftUI
import PhotosUI
import SwiftData

struct ProfileView: View {
    @AppStorage("userName") private var userName = "Inspo User"
    @AppStorage("userBio") private var userBio = "Design enthusiast & collector."
    @Query private var savedItems: [SavedItem]
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Profile Header
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            if let profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundStyle(.gray)
                                    .frame(width: 100, height: 100)
                            }
                            
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Text("Edit Photo")
                                    .font(.caption)
                                    .buttonStyle(.bordered)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                // Section 2: Info
                Section("About You") {
                    TextField("Name", text: $userName)
                    TextField("Bio", text: $userBio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Section 3: Stats
                Section("Statistics") {
                    HStack {
                        Text("Inspirations Collected")
                        Spacer()
                        Text("\(savedItems.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Websites")
                        Spacer()
                        Text("\(savedItems.filter { $0.url != nil }.count)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Section 4: Share
                Section {
                    ShareLink(
                        item: generateShareSummary(),
                        subject: Text("My InspoFlow Profile"),
                        message: Text("Check out my collection stats!")
                    ) {
                        Label("Share Profile", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Profile")
            .onChange(of: selectedItem) {
                Task {
                    if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = uiImage
                        saveImageToDisk(data: data)
                    }
                }
            }
            .onAppear {
                loadImageFromDisk()
            }
        }
    }
    
    // MARK: - Persistence Helpers (Simple Disk Storage)
    
    private func saveImageToDisk(data: Data) {
        let url = getDocumentsDirectory().appendingPathComponent("profile.jpg")
        try? data.write(to: url)
    }
    
    private func loadImageFromDisk() {
        let url = getDocumentsDirectory().appendingPathComponent("profile.jpg")
        if let data = try? Data(contentsOf: url) {
            profileImage = UIImage(data: data)
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func generateShareSummary() -> String {
        return """
        🚀 InspoFlow Profile
        Name: \(userName)
        Bio: \(userBio)
        
        I've collected \(savedItems.count) design inspirations!
        """
    }
}

#Preview {
    ProfileView()
}
