import Foundation
import FirebaseAuth
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()
    @Published var verificationID: String?
    
    // MARK: - Phone Auth
    func startPhoneVerification(phoneNumber: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Firebase Phone Auth
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let verificationID = verificationID {
                self.verificationID = verificationID
                completion(.success(verificationID))
            }
        }
    }
    
    func verifyPhoneCode(verificationID: String, code: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let authResult = authResult {
                completion(.success(authResult))
            }
        }
    }
    
    // MARK: - Email Auth (Link)
    func sendEmailLink(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let actionCodeSettings = ActionCodeSettings()
        // Uses the default Firebase project hosting URL usually found in config
        // Note: User needs to whitelist the domain in Firebase Console if using custom.
        // For basic setup, we try to use the bundle ID as the redirect context.
        actionCodeSettings.url = URL(string: "https://google.com") // Fallback redirect
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        
        Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            UserDefaults.standard.set(email, forKey: "EmailLink")
            completion(.success(()))
        }
    }
    
    func handleUrl(_ url: URL, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        let link = url.absoluteString
        if Auth.auth().isSignIn(withEmailLink: link) {
            guard let email = UserDefaults.standard.string(forKey: "EmailLink") else {
                // If email isn't saved, we might ask user. For now error.
                completion(.failure(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Email used for sign-in not found on device"])))
                return
            }
            
            Auth.auth().signIn(withEmail: email, link: link) { result, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                if let result = result {
                    completion(.success(result))
                }
            }
        }
    }
}
