import Foundation

// =========================================================================
// MARK: - 🟢 NVIDIA NIM CONFIGURATION
// Configure your NVIDIA API credentials here.
// Get your free API Key at: https://build.nvidia.com/moonshot-ai/kimi-k2_5
// =========================================================================

struct NvidiaConfig {
    // API Endpoint for NVIDIA NIM (OpenAI Compatible)
    static let endpoint = "https://integrate.api.nvidia.com/v1/chat/completions"
    
    // Model ID for Kimi AI
    static let modelId = "moonshotai/kimi-k2.5" 
    
    // Key: Your NVIDIA API Key (starts with nvapi-)
    static let apiKey = "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"
}
