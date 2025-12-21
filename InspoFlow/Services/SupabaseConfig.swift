import Foundation

// =========================================================================
// MARK: - ⚡️ SUPABASE CONFIGURATION
// Configure your Supabase credentials here.
// =========================================================================

struct SupabaseConfig {
    // URL: Your Supabase Project URL
    static let url = "https://sudnkclqmxadryrmdtmx.supabase.co"
    
    // Key: Your Supabase Anon Key (public API key)
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN1ZG5rY2xxbXhhZHJ5cm1kdG14Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwNDIxNTEsImV4cCI6MjA4MTYxODE1MX0.MzDxyxRRn_xDqbwEPNKYadpJxcIPmJvNbAdC4ho1qYQ"
    
    // Bucket Name for Screenshots (Must be 'public')
    static let storageBucket = "screenshots"
    
    // Table Name for Metadata
    static let databaseTable = "saved_items"
}
