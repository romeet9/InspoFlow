import Foundation
import UIKit
import Combine

@MainActor
class NvidiaAIService: ObservableObject {
    @Published var isAnalyzing = false
    
    // Result matching the app's expectation (Same as HuggingFaceService)
    struct AnalysisResult: Codable {
        let title: String
        let summary: String
        let category: String
        let tags: [String]?
        let url: String?
    }
    
    func analyze(image: UIImage) async -> AnalysisResult {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        print("\n==========================================")
        print("🟢 STARTING NVIDIA (KIMI AI) ANALYSIS")
        
        let token = NvidiaConfig.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if token == "YOUR_NVIDIA_API_KEY" || token.isEmpty {
            return errorResult("Please configure API Key in NvidiaConfig.swift")
        }
        print("🔑 Using NVIDIA Key: \(token.prefix(4))...\(token.suffix(4))")
        print("==========================================\n")
        
        // 1. Prepare Image
        // Resize to optimize for Vision/Base64 limits
        let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 1024, height: 1024))
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            return errorResult("Failed to process image data.")
        }
        let base64Image = imageData.base64EncodedString()
        let dataUri = "data:image/jpeg;base64,\(base64Image)"
        
        // 2. Prepare Request
        guard let url = URL(string: NvidiaConfig.endpoint) else { return errorResult("Invalid URL") }
        
        // 3. Prompt Engineering (Optimized for Kimi)
        let promptText = """
        Analyze this UI screenshot. Extract the following in strict JSON format:
        - title: The specific Name of the App, Website, or Brand visible.
        - summary: One sentence description of the visual style and content.
        - category: 'app' or 'website'.
        - tags: A SINGLE string in an array (e.g. ['SaaS']). Choose the ONE most relevant category from: ['Design Inspiration', 'SaaS', 'UI Kit', 'Icon Library']. If none fit, use a single descriptive style tag. Do NOT return multiple tags.
        - url: The exact URL visible in the address bar, or null.
        
        Output valid JSON only. No markdown formatting.
        """
        
        // OpenAI-Compatible Payload
        let payload: [String: Any] = [
            "model": NvidiaConfig.modelId,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": promptText],
                        ["type": "image_url", "image_url": ["url": dataUri]]
                    ]
                ]
            ],
            "max_tokens": 512,
            "stream": false
        ]

        do {
            let httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = httpBody
            
            print("🚀 Sending Request to NVIDIA NIM (\(NvidiaConfig.modelId))...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                 return errorResult("Network Error")
            }
            
            if httpResponse.statusCode != 200 {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown"
                print("❌ NVIDIA Error (\(httpResponse.statusCode)): \(errorMsg)")
                return errorResult("NVIDIA API Error: \(httpResponse.statusCode)")
            }
            
            // 4. Parse Response (OpenAI Format)
            struct NIMResponse: Decodable {
                struct Choice: Decodable {
                    struct Message: Decodable {
                        let content: String
                    }
                    let message: Message
                }
                let choices: [Choice]
            }
            
            let chatResp = try JSONDecoder().decode(NIMResponse.self, from: data)
            guard let content = chatResp.choices.first?.message.content else {
                return errorResult("No content generated.")
            }
            
            print("✨ Kimi AI Output: \(content)")
            
            // Clean Markdown (e.g. ```json ... ```)
            let cleanText = content
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let resultData = cleanText.data(using: .utf8),
                  let finalResult = try? JSONDecoder().decode(AnalysisResult.self, from: resultData) else {
                
                // Fallback attempt if simple text
                if !cleanText.isEmpty && cleanText.count < 150 {
                     return AnalysisResult(title: "Analyzed Image", summary: cleanText, category: "website", tags: ["Uncategorized"], url: nil)
                }
                return errorResult("Failed to parse JSON response from Kimi.")
            }
            
            print("✅ Analysis Success: \(finalResult.title)")
            return finalResult
            
        } catch {
            print("❌ Network Error: \(error)")
            return errorResult("Connection failed: \(error.localizedDescription)")
        }
    }
    
    // Add Chat Capability
    func chat(message: String) async -> String {
        let token = NvidiaConfig.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if token == "YOUR_NVIDIA_API_KEY" || token.isEmpty {
            return "Please configure API Key in NvidiaConfig.swift"
        }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        guard let url = URL(string: NvidiaConfig.endpoint) else { return "Invalid URL" }
        
        let systemPrompt = """
        You are a strict AI assistant for a web design inspiration app.
        
        RULES:
        1. Answer ONLY questions related to UI/UX design, website inspiration, or design tools.
        2. If a user asks about anything else (e.g. code, life, general knowledge), politely refuse: "I can only help with design inspiration."
        3. When recommending websites, provide ONLY the direct valid URLs (e.g. https://dribbble.com).
        4. DO NOT write descriptions, lists, or introductions. Just output the links separated by spaces.
        5. Your goal is to populate the user's feed with link cards, not text.
        """
        
        let payload: [String: Any] = [
            "model": NvidiaConfig.modelId,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": message]
            ],
            "max_tokens": 512,
            "stream": false
        ]
        
        do {
            let httpBody = try JSONSerialization.data(withJSONObject: payload)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = httpBody
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else { return "Network Error" }
            if httpResponse.statusCode != 200 { return "AI Error (\(httpResponse.statusCode))" }
            
            struct NIMResponse: Decodable {
                struct Choice: Decodable {
                    struct Message: Decodable {
                        let content: String
                    }
                    let message: Message
                }
                let choices: [Choice]
            }
            
            let chatResp = try JSONDecoder().decode(NIMResponse.self, from: data)
            return chatResp.choices.first?.message.content ?? "No response."
            
        } catch {
            return "Connection error: \(error.localizedDescription)"
        }
    }
    
    private func errorResult(_ msg: String) -> AnalysisResult {
        return AnalysisResult(title: "Error", summary: msg, category: "error", tags: [], url: nil)
    }
    
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = widthRatio > heightRatio ?  CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
}
