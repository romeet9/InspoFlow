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
                // Section 1: Info
                Section("About You") {
                    TextField("Name", text: $userName)
                    TextField("Bio", text: $userBio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Section 2: Stats
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
                
                // Section 3: Share
                Section {
                    ShareLink(
                        item: generateShareSummary(),
                        subject: Text("My InspoFlow Profile"),
                        message: Text("Check out my collection stats!")
                    ) {
                        Label("Share Profile", systemImage: "square.and.arrow.up")
                    }
                }
                
                // Section 4: Account
                Section {
                    Button(role: .destructive, action: signOut) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
    
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
        
        I've collected \(savedItems.count) design inspirations!
        """
    }
}

#Preview {
    ProfileView()
}
