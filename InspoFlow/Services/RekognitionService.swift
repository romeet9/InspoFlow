import Foundation
import UIKit
import CryptoKit
import Combine

// =========================================================================
// MARK: - ☁️ AWS CONFIGURATION
// Configure your AWS credentials here.
// =========================================================================

struct AWSConfig {
    static let accessKey = ""
    static let secretKey = ""
    static let region = "us-east-1" // Change if needed (e.g. us-west-2, eu-west-1)
    static let service = "rekognition"
}

// =========================================================================

enum RekognitionError: Error {
    case invalidCredentials
    case imageProcessingFailed
    case apiError(String)
    case invalidResponse
}

@MainActor
class RekognitionService: ObservableObject {
    @Published var isAnalyzing = false
    
    // Result matching the app's expectation
    struct AnalysisResult: Codable {
        let title: String
        let summary: String
        let category: String
        let url: String?
    }
    
    // AWS Response Models
    private struct DetectTextResponse: Codable {
        struct TextDetection: Codable {
            let DetectedText: String
            let itemType: String // Renamed to avoid reserved keyword 'Type'
            let Confidence: Float
            
            enum CodingKeys: String, CodingKey {
                case DetectedText
                case itemType = "Type"
                case Confidence
            }
        }
        let TextDetections: [TextDetection]?
    }
    
    func analyze(image: UIImage) async -> AnalysisResult {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        print("\n==========================================")
        print("☁️ STARTING AWS REKOGNITION ANALYSIS")
        print("==========================================\n")
        
        // 1. Prepare Image (Resize & Encode)
        // AWS Rekognition limit is 5MB for direct upload. Resizing ensures we are well under.
        let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 1024, height: 1024))
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            return AnalysisResult(title: "Error", summary: "Failed to process image.", category: "error", url: nil)
        }
        
        // 2. Prepare Request Payload
        let base64Image = imageData.base64EncodedString()
        let jsonBody: [String: Any] = [
            "Image": [
                "Bytes": base64Image
            ]
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: jsonBody) else {
            return AnalysisResult(title: "Error", summary: "Failed to create request body.", category: "error", url: nil)
        }
        
        // 3. Create & Send Request
        do {
            let endpoint = "https://rekognition.\(AWSConfig.region).amazonaws.com/"
            let target = "RekognitionService.DetectText"
            
            let request = try createSignedRequest(endpoint: endpoint, target: target, bodyData: httpBody)
            
            print("🚀 Sending Request to AWS...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
                print("❌ AWS Error: \(errorMsg)")
                return AnalysisResult(title: "AWS Error", summary: "The AI service returned an error.", category: "error", url: nil)
            }
            
            print("✅ AWS Response Received. Size: \(data.count) bytes")
            
            // 4. Decode & Process
            let decoder = JSONDecoder()
            let detectResponse = try decoder.decode(DetectTextResponse.self, from: data)
            
            let result = processAWSResult(detectResponse)
            print("✨ Analysis Success: \(result.title)")
            return result
            
        } catch {
            print("❌ Network/Decoding Error: \(error)")
            return AnalysisResult(title: "Connection Error", summary: "Could not reach the AI service.", category: "error", url: nil)
        }
    }
    
    // MARK: - LOGIC: Post-Processing
    
    private func processAWSResult(_ response: DetectTextResponse) -> AnalysisResult {
        guard let detections = response.TextDetections else {
            return AnalysisResult(title: "No Text Found", summary: "The image appears to be empty.", category: "website", url: nil)
        }
        
        // Filter for LINES only (ignore individual words for better context)
        let lines = detections.filter { $0.itemType == "LINE" && $0.Confidence > 60.0 } // Lowered confidence slightly for odd fonts
        let allText = lines.map { $0.DetectedText }
        
        print("📝 Detected Lines: \(allText)")
        
        // 1. Find URL (Enhanced Detection)
        var detectedURL: String? = nil
        
        // A. Standard Detector (http, https, www)
        let types = NSTextCheckingResult.CheckingType.link.rawValue
        let detector = try? NSDataDetector(types: types)
        
        for text in allText {
            if let match = detector?.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
                if let url = match.url {
                     detectedURL = url.absoluteString
                     break
                }
            }
        }
        
        // B. Fallback: Heuristic Regex for modern domains (e.g. 21st.dev, linear.app)
        if detectedURL == nil {
            // Pattern: start-of-word + alphanumeric/dashes + . + TLD + end-of-word
            // Common modern TLDs
            let tldPattern = "(?:com|org|net|io|dev|app|ai|co|uk|tech|design|xyz|me|so)"
            let domainPattern = "\\b[a-zA-Z0-9-]+\\.\(tldPattern)\\b"
            
            for text in allText {
                if let range = text.range(of: domainPattern, options: [.regularExpression, .caseInsensitive]) {
                    let candidate = String(text[range])
                    // Sanity check: ensure no spaces
                    if !candidate.contains(" ") {
                        // Prepend https:// for usability
                        detectedURL = "https://" + candidate
                        print("🔍 Heuristic URL Match: \(candidate)")
                        break
                    }
                }
            }
        }
        
        // 2. Find Title (Largest/First line that ISN'T the URL and is substantial)
        let titleCandidate = lines.first { line in
            let txt = line.DetectedText
            // Filter out the URL we just found
            if let url = detectedURL, txt.contains(url.replacingOccurrences(of: "https://", with: "")) { return false }
            // Filter out system text
            if txt.contains(":") && txt.count < 6 { return false } // 9:41
            // Filter out common UI words if they appear alone
            if ["Get Started", "Login", "Sign Up", "Menu", "Context"].contains(txt) { return false }
            
            return txt.count > 3
        }
        
        // If the URL domain is actually the best title (e.g. "21st.dev"), use it if no other title found
        let title = titleCandidate?.DetectedText ?? (detectedURL != nil ? URL(string: detectedURL!)?.host : "New Inspiration") ?? "New Inspiration"
        
        // 3. Summary (Enhanced Logic)
        // Filter out timestamp-like strings (e.g. "9:41", "12:00 PM", "3:14")
        let timePattern = "^\\d{1,2}:\\d{2}"
        
        let validLines = allText.filter { text in
            if text == title || text == detectedURL { return false }
            // Filter timestamps
            if text.range(of: timePattern, options: .regularExpression) != nil { return false }
            // Filter common UI noise
            if ["Menu", "Back", "Done", "Cancel", "Search", "Share", "Settings", "Get Started", "Login"].contains(text) { return false }
            // Filter short nonsense
            if text.count < 5 { return false }
            // Filter likely symbol garbage
            if text.hasPrefix("=") || text.hasPrefix("+") { return false }
            return true
        }
        
        // Prioritize longer descriptive lines to form a paragraph
        let description = validLines
            .filter { $0.components(separatedBy: " ").count > 3 } // At least 4 words to be a sentence
            .prefix(5) // Take top 5 meaningful lines
            .joined(separator: " ") // Join with space for paragraph flow
            
        // Fallback to keywords if no sentences found
        let keywords = validLines.prefix(8).joined(separator: ", ")
        
        let finalSummary = description.isEmpty ? keywords : description
        let truncatedSummary = String(finalSummary.prefix(500))
        
        return AnalysisResult(
            title: String(title ?? "Inspiration"),
            summary: truncatedSummary.isEmpty ? "No description available." : truncatedSummary,
            category: "website",
            url: detectedURL
        )
    }
    
    // MARK: - AWS SIGNATURE V4
    
    private func createSignedRequest(endpoint: String, target: String, bodyData: Data) throws -> URLRequest {
        guard let url = URL(string: endpoint) else { throw RekognitionError.invalidCredentials }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let amzDate = dateFormatter.string(from: now)
        
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateStamp = dateFormatter.string(from: now)
        
        // Headers
        let host = url.host!
        request.addValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        request.addValue(target, forHTTPHeaderField: "X-Amz-Target")
        request.addValue(amzDate, forHTTPHeaderField: "X-Amz-Date")
        request.addValue(host, forHTTPHeaderField: "Host")
        
        // Canonical Request
        let canonicalUri = "/"
        let canonicalQuery = ""
        let canonicalHeaders = "content-type:application/x-amz-json-1.1\nhost:\(host)\nx-amz-date:\(amzDate)\nx-amz-target:\(target)\n"
        let signedHeaders = "content-type;host;x-amz-date;x-amz-target"
        let payloadHash = SHA256.hash(data: bodyData).map { String(format: "%02x", $0) }.joined()
        
        let canonicalRequest = """
        POST
        \(canonicalUri)
        \(canonicalQuery)
        \(canonicalHeaders)
        \(signedHeaders)
        \(payloadHash)
        """
        
        // String to Sign
        let algorithm = "AWS4-HMAC-SHA256"
        let credentialScope = "\(dateStamp)/\(AWSConfig.region)/\(AWSConfig.service)/aws4_request"
        let canonicalRequestHash = SHA256.hash(data: Data(canonicalRequest.utf8)).map { String(format: "%02x", $0) }.joined()
        
        let stringToSign = """
        \(algorithm)
        \(amzDate)
        \(credentialScope)
        \(canonicalRequestHash)
        """
        
        // Signature Calculation
        let kSecret = "AWS4" + AWSConfig.secretKey
        let kDate = hmac(key: Data(kSecret.utf8), message: dateStamp)
        let kRegion = hmac(key: kDate, message: AWSConfig.region)
        let kService = hmac(key: kRegion, message: AWSConfig.service)
        let kSigning = hmac(key: kService, message: "aws4_request")
        let signatureData = hmac(key: kSigning, message: stringToSign)
        let signature = signatureData.map { String(format: "%02x", $0) }.joined()
        
        // Authorization Header
        let authorizationHeader = "\(algorithm) Credential=\(AWSConfig.accessKey)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"
        request.addValue(authorizationHeader, forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    private func hmac(key: Data, message: String) -> Data {
        let key = SymmetricKey(data: key)
        let signature = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: key)
        return Data(signature)
    }
    
    // MARK: - HELPERS
    
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
