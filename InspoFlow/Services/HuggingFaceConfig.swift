import Foundation

struct HuggingFaceConfig {
    // Get your free token at https://huggingface.co/settings/tokens
    // Ensure it has 'Read' and 'Inference' permissions.
    // MUST ACCEPT LICENSE AT: https://huggingface.co/meta-llama/Llama-3.2-11B-Vision-Instruct
    static let apiToken = "YOUR_HF_TOKEN" 
    
    // Model ID to use. 
    // Explicitly allowed by HF API Error Message (Qwen 2.5 is supported on v1/chat).
    static let modelId = "Qwen/Qwen2.5-VL-7B-Instruct"
}

