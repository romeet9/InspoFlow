import Foundation

// =========================================================================
// MARK: - ⚡️ SUPABASE CONFIGURATION
// Configure your Supabase credentials here.
// =========================================================================

struct SupabaseConfig {
    // URL: Your Supabase Project URL
    static let url = "https://sudnkclqmxadryrmdtmx.supabase.co"
    
    // Key: Your Supabase Anon Key (public API key)
    static let anonKey = "YOUR_SUPABASE_ANON_KEY"
    
    // Bucket Name for Screenshots (Must be 'public')
    static let storageBucket = "screenshots"
    
    // Table Name for Metadata
    static let databaseTable = "saved_items"
}
