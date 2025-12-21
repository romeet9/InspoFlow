import Foundation
import UIKit

@MainActor
class SupabaseStorageService {
    static let shared = SupabaseStorageService()
    
    private init() {}
    
    /// Uploads an image to Supabase Storage and returns the public URL.
    /// - Parameters:
    ///   - data: The JPEG data.
    ///   - filename: The filename (e.g., "my-image.jpg").
    /// - Returns: The full public URL of the uploaded item.
    func uploadImage(data: Data, filename: String) async throws -> String {
        // 1. Prepare Endpoint
        // POST /storage/v1/object/{bucket}/{path}
        let cleanURL = SupabaseConfig.url.trimmingCharacters(in: .init(charactersIn: "/"))
        let endpoint = "\(cleanURL)/storage/v1/object/\(SupabaseConfig.storageBucket)/\(filename)"
        
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        // 2. Prepare Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        print("⚡️ Uploading to Supabase Storage: \(filename)...")
        
        // 3. Send
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            let errorMsg = String(data: responseData, encoding: .utf8) ?? "Unknown Error"
            print("❌ Supabase Upload Failed: \(httpResponse.statusCode)")
            print("❌ Error Body: \(errorMsg)")
            throw URLError(.badServerResponse)
        }
        
        print("✅ Supabase Upload Success!")
        
        // 4. Construct Public URL
        // GET /storage/v1/object/public/{bucket}/{path}
        let publicURL = "\(cleanURL)/storage/v1/object/public/\(SupabaseConfig.storageBucket)/\(filename)"
        return publicURL
    }
}
