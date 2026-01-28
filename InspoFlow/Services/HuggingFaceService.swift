import Foundation
import UIKit
import Combine

@MainActor
class HuggingFaceService: ObservableObject {
    @Published var isAnalyzing = false
    
    // Result matching the app's expectation
    struct AnalysisResult: Codable {
        let title: String
        let summary: String
        let category: String
        let tags: [String]? // [NEW] Multiple tags
        let url: String?
    }
    
    func analyze(image: UIImage) async -> AnalysisResult {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        print("\n==========================================")
        print("🤗 STARTING HUGGINGFACE ANALYSIS")
        
        let token = HuggingFaceConfig.apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        if token == "YOUR_HF_TOKEN" {
            return errorResult("Please configure API Token in HuggingFaceConfig.swift")
        }
        print("🔑 Using Token in Analyze: \(token.prefix(4))...\(token.suffix(4))")
        
        print("==========================================\n")
        
        // 1. Prepare Image
        // Resize to avoid timeouts or payload limits (1024px is usually good)
        let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 1024, height: 1024))
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            return errorResult("Failed to process image data.")
        }
        let base64Image = imageData.base64EncodedString()
        let dataUri = "data:image/jpeg;base64,\(base64Image)"
        
        // 2. Prepare Request
        // Using OpenAI-compatible endpoint for maximum reliability with Llama 3.2
        let endpoint = "https://router.huggingface.co/v1/chat/completions"
        guard let url = URL(string: endpoint) else { return errorResult("Invalid URL") }
        
        // 3. Prompt Engineering
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
            "model": HuggingFaceConfig.modelId,
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
            let token = HuggingFaceConfig.apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = httpBody
            
            print("🚀 Sending Request to HuggingFace (\(HuggingFaceConfig.modelId))...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                 return errorResult("Network Error")
            }
            
            if httpResponse.statusCode != 200 {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown"
                print("❌ HF Error (\(httpResponse.statusCode)): \(errorMsg)")
                
                if httpResponse.statusCode == 404 {
                    return errorResult("Model not found. Please accept license terms on HuggingFace website.")
                }
                if httpResponse.statusCode == 503 {
                    return errorResult("Model loading... try again in 30s.")
                }
                return errorResult("HF API Error: \(httpResponse.statusCode)")
            }
            
            // 4. Parse Response (OpenAI Format)
            struct HFResponse: Decodable {
                struct Choice: Decodable {
                    struct Message: Decodable {
                        let content: String
                    }
                    let message: Message
                }
                let choices: [Choice]
            }
            
            let chatResp = try JSONDecoder().decode(HFResponse.self, from: data)
            guard let content = chatResp.choices.first?.message.content else {
                return errorResult("No content generated.")
            }
            
            print("✨ HF Output: \(content)")
            
            // Clean Markdown (e.g. ```json ... ```)
            let cleanText = content
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let resultData = cleanText.data(using: .utf8),
                  let finalResult = try? JSONDecoder().decode(AnalysisResult.self, from: resultData) else {
                
                // Fallback attempt if simple text
                if !cleanText.isEmpty && cleanText.count < 100 {
                     return AnalysisResult(title: "Analyzed Image", summary: cleanText, category: "website", tags: ["Uncategorized"], url: nil)
                }
                return errorResult("Failed to parse JSON response.")
            }
            
            print("✅ Analysis Success: \(finalResult.title)")
            return finalResult
            
        } catch {
            print("❌ Network Error: \(error)")
            return errorResult("Connection failed: \(error.localizedDescription)")
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
    func chat(message: String) async -> String {
        let token = HuggingFaceConfig.apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if token == "YOUR_HF_TOKEN" {
            return "Please configure your API Token in HuggingFaceConfig.swift"
        }
        
        print("🔑 Using Token: \(token.prefix(4))...\(token.suffix(4))")
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // 1. Prepare Request
        let endpoint = "https://router.huggingface.co/v1/chat/completions"
        guard let url = URL(string: endpoint) else { return "Error: Invalid URL" }
        
        let systemPrompt = """
        You are a strict AI assistant for a web design inspiration app.
        
        RULES:
        1. Answer ONLY questions related to UI/UX design, website inspiration, or design tools.
        2. If a user asks about anything else (e.g. code, life, general knowledge), politely refuse: "I can only help with design inspiration."
        3. When recommending websites, provide ONLY the direct valid URLs (e.g. https://dribbble.com).
        4. DO NOT write descriptions, lists, or introductions. Just output the links separated by spaces.
        5. Your goal is to populate the user's feed with link cards, not text.
        """
        
        // OpenAI-Compatible Payload
        let payload: [String: Any] = [
            "model": HuggingFaceConfig.modelId,
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
            
            guard let httpResponse = response as? HTTPURLResponse else {
                 return "Connection Error"
            }
            
            if httpResponse.statusCode != 200 {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown Error"
                print("HF Chat Error: \(errorBody)")
                if httpResponse.statusCode == 401 {
                    return "Invalid API Token. Please check HuggingFaceConfig.swift."
                }
                return "AI Error (\(httpResponse.statusCode)). Please try again."
            }
            
            // Re-use existing struct for parsing
            struct HFResponse: Decodable {
                struct Choice: Decodable {
                    struct Message: Decodable {
                        let content: String
                    }
                    let message: Message
                }
                let choices: [Choice]
            }
            
            let chatResp = try JSONDecoder().decode(HFResponse.self, from: data)
            return chatResp.choices.first?.message.content ?? "No response generated."
            
        } catch {
            print("Chat Error: \(error)")
            return "Connection failed. Please check your internet."
        }
    }
}
