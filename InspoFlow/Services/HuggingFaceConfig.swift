import Foundation

struct HuggingFaceConfig {
    // Get your free token at https://huggingface.co/settings/tokens
    // Ensure it has 'Read' and 'Inference' permissions.
    // MUST ACCEPT LICENSE AT: https://huggingface.co/meta-llama/Llama-3.2-11B-Vision-Instruct
    static let apiToken = "YOUR_HF_TOKEN" 
    
    // Model ID to use. 
    // Switched to 72B as 7B was throwing 500 Internal Errors.
    static let modelId = "Qwen/Qwen2.5-VL-72B-Instruct"
}
