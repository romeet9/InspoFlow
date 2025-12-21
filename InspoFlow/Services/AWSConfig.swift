import Foundation

// =========================================================================
// MARK: - ☁️ AWS CONFIGURATION
// Configure your AWS credentials here.
// =========================================================================

struct AWSConfig {
    // IAM Credentials for Rekognition (Standard AWS SigV4)
    static let accessKey = "YOUR_ACCESS_KEY" // Placeholder
    static let secretKey = "YOUR_SECRET_KEY"
    
    // Bedrock Long-Term API Key (Bearer Auth)
    static let bedrockApiKey = "YOUR_BEDROCK_API_KEY"
    static let region = "us-east-1"
    static let service = "rekognition" // Default service, can be overridden
    
    // Cloud Persistence Config
    static let s3BucketName = "inspoflow-assets" // S3 Buckets MUST be lowercase
    static let dynamoTableName = "InspoFlowItems"
}
