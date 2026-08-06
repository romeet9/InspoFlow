import SwiftUI
import SwiftData
import FirebaseAuth

struct ProfileView: View {
    @AppStorage("userName") private var userName = "Inspo User"
    @AppStorage("userBio") private var userBio = "Design enthusiast & collector."
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @Query private var savedItems: [SavedItem]
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Header Section
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .foregroundStyle(.gray.opacity(0.3))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Name", text: $userName)
                                .font(.headline)
                            
                            TextField("Bio", text: $userBio)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // MARK: - Stats Section
                Section {
                    LabeledContent("Inspirations", value: "\(savedItems.count)")
                    LabeledContent("Websites", value: "\(savedItems.filter { $0.url != nil }.count)")
                    LabeledContent("Apps", value: "\(savedItems.filter { $0.type == .app }.count)")
                } header: {
                    Text("Collection Stats")
                }
                
                // MARK: - Actions
                Section {
                    ShareLink(
                        item: generateShareSummary(),
                        subject: Text("My InspoFlow Profile"),
                        message: Text("Check out my collection stats!")
                    ) {
                        Label("Share Profile", systemImage: "square.and.arrow.up")
                    }
                    .foregroundStyle(.blue)
                }
                
                Section {
                    Button(role: .destructive, action: signOut) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } footer: {
                    Text("InspoFlow v1.0.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // Logic (Unchanged)
    private func signOut() {
        do {
            try Auth.auth().signOut()
            withAnimation {
                hasCompletedOnboarding = false
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    private func generateShareSummary() -> String {
        return """
        🚀 InspoFlow Profile
        Name: \(userName)
        Bio: \(userBio)
        
        I've collected \(savedItems.count) inspirations on InspoFlow!
        """
    }
}

#Preview {
    ProfileView()
}
