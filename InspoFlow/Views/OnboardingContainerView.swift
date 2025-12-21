import SwiftUI
import Combine
import PhotosUI
import AuthenticationServices
import FirebaseAuth

// MARK: - Navigation Enum
enum OnboardingPath: Hashable {
    case emailInput
    case checkEmail(email: String)
    case nameInput
    case permissions
    case bioInput
}

// MARK: - Container View
struct OnboardingContainerView: View {
    @State private var path = NavigationPath()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("userBio") private var userBio = ""
    
    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView {
                path.append(OnboardingPath.emailInput)
            }
            .navigationDestination(for: OnboardingPath.self) { destination in
                switch destination {
                case .emailInput:
                    EmailInputView { email in
                        AuthService.shared.sendEmailLink(email: email) { result in
                            switch result {
                            case .success:
                                path.append(OnboardingPath.checkEmail(email: email))
                            case .failure(let error):
                                print("Email Link Error: \(error.localizedDescription)")
                            }
                        }
                    }
                case .checkEmail(let email):
                    CheckEmailView(email: email) {
                        path.append(OnboardingPath.nameInput)
                    }
                case .nameInput:
                    NameInputView { name in
                        userName = name
                        path.append(OnboardingPath.permissions)
                    }
                case .permissions:
                    PermissionsView {
                        path.append(OnboardingPath.bioInput)
                    }
                case .bioInput:
                    BioInputView { bio in
                        userBio = bio
                        completeOnboarding()
                    }
                }
            }
        }
        .tint(.primary)
        .onAppear {
             // Listener for Email Link Auto-Login
             _ = Auth.auth().addStateDidChangeListener { auth, user in
                 if user != nil {
                     if userName.isEmpty {
                         // Advance logic handled either by user tap or manual check
                     }
                 }
             }
        }
    }
    
    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - 1. Welcome View (Splash)
struct WelcomeView: View {
    var onContinue: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.black)
                .padding(.bottom, 20)
            
            Text("Say hello to InspoFlow,\nyour Living History")
                .font(.system(size: 32, weight: .regular))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
    }
}



// MARK: - 3. Email Input View
struct EmailInputView: View {
    var onContinue: (String) -> Void
    @State private var email = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var isValidEmail: Bool {
        // Simple regex for basic validation
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("What's your email?")
                    .font(.system(size: 30, weight: .regular))
                
                Text("We'll send a code to this email to\nverify your sign in")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            TextField("name@mail.com", text: $email)
                .font(.system(size: 24, weight: .regular))
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                )
                .padding(.horizontal, 24)
                .padding(.top, 40)
            
            Spacer()
            
            Button(action: { onContinue(email) }) {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black.opacity(isValidEmail ? 1 : 0.3))
                    .clipShape(Capsule())
            }
            .disabled(!isValidEmail)
            .padding(.horizontal, 24)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .onAppear { isFocused = true }
        .navigationBarBackButtonHidden(true) // FIX: Hides System Back Button
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.black)
                }
            }
        }
    }
}

// MARK: - 4. Check Email View
struct CheckEmailView: View {
    let email: String
    var onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text("Check your email")
                    .font(.system(size: 30, weight: .regular))
                    .multilineTextAlignment(.center)
                
                Text("We sent a login link to\n\(email)")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            .padding(.horizontal, 24)
            
            Image(systemName: "envelope.badge")
                .font(.system(size: 80))
                .foregroundStyle(.black)
                .padding(.top, 60)
            
            Text("Tap the link in the email to\nautomatically log in.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 24)
            
            Spacer()
            
            Button(action: {
                // Bypass for Demo/Investor Flow
                onContinue()
            }) {
                Text("I've Verified")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - 5. Name Input View
struct NameInputView: View {
    var onContinue: (String) -> Void
    @State private var name = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userName") private var storedName = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("What's your name?")
                    .font(.system(size: 30, weight: .regular))
                
                Text("This will be the name InspoFlow uses\nto refer to you")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            TextField("e.g. Samantha", text: $name)
                .font(.system(size: 24, weight: .regular))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($isFocused)
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                )
                .padding(.horizontal, 24)
                .padding(.top, 40)
            
            Spacer()
            
            Button(action: { onContinue(name) }) {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black.opacity(name.isEmpty ? 0.3 : 1))
                    .clipShape(Capsule())
            }
            .disabled(name.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .onAppear {
            isFocused = true
            if !storedName.isEmpty {
                name = storedName
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.black)
                }
            }
        }
    }
}

// MARK: - 6. Permissions View
struct PermissionsView: View {
    var onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text("Enable permissions")
                    .font(.system(size: 30, weight: .regular))
                    .multilineTextAlignment(.center)
                
                Text("InspoFlow works best with access to the\nfollowing permissions")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            
            VStack(spacing: 16) {
                PermissionCard(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Allows InspoFlow to deliver timely reminders and proactive messages"
                )
                PermissionCard(
                    icon: "calendar",
                    title: "Calendar",
                    description: "Allows InspoFlow to see what your day is like and help you plan ahead"
                )
                PermissionCard(
                    icon: "location.fill",
                    title: "Location",
                    description: "Allows InspoFlow to personalize suggestions to your location"
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.black)
                }
            }
        }
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.black)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemBackground)) // Light gray card
        .cornerRadius(20)
    }
}

// MARK: - 7. Bio Input View
struct BioInputView: View {
    var onContinue: (String) -> Void
    @State private var bio = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text("One more thing")
                    .font(.system(size: 30, weight: .regular))
                    .multilineTextAlignment(.center)
                
                Text("Help InspoFlow get to know you by\nwriting a short letter")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Bio Card
            VStack(alignment: .leading) {
                if bio.isEmpty {
                    Text("Introduce yourself...")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8) // Adjustment to align with text
                }
                
                TextEditor(text: $bio)
                    .font(.title2)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .frame(maxHeight: .infinity)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .frame(height: 400)
            .background(Color.white)
            .cornerRadius(32)
            .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: { onContinue(bio) }) {
                Text("Start your journey")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black) // Always enabled
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white) // Using white throughout, or maybe a very subtle gray for background to make the white card pop?
        // Screenshot shows a white card on a gradient. User said "no gradient".
        // I will use `systemGroupedBackground` for the screen background here to make the white card pop.
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .onAppear {
             // Delay focus slightly for effect
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                 isFocused = true
             }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.black)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                 Button("Done") {
                     // Action if needed, or just let 'Start your journey' handle it
                     isFocused = false
                 }
                 .foregroundStyle(.primary)
            }
        }
    }
}

#Preview {
    OnboardingContainerView()
}
