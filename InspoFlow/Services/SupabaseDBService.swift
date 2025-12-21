import Foundation

@MainActor
class SupabaseDBService {
    static let shared = SupabaseDBService()
    
    private init() {}
    
    // MARK: - Models
    // Supabase returns standard JSON arrays, easier than DynamoDB!
    
    struct SupabaseItem: Codable {
        let id: String
        let url: String?
        let title: String
        let summary: String?
        let type: String
        let timestamp: String
        let s3_url: String // Mapping to snake_case column in Supabase
        let tags: [String]? // [NEW] Tags support
        
        enum CodingKeys: String, CodingKey {
            case id
            case url
            case title
            case summary
            case type
            case timestamp = "created_at" // We can use 'created_at' or custom 'timestamp'
            case s3_url
            case tags
        }
    }
    
    // MARK: - Actions
    
    /// Saves an item to the 'saved_items' table.
    func saveItem(item: SavedItem, imageURL: String) async throws {
        // 1. Prepare Endpoint
        // POST /rest/v1/{table}
        let cleanURL = SupabaseConfig.url.trimmingCharacters(in: .init(charactersIn: "/"))
        let endpoint = "\(cleanURL)/rest/v1/\(SupabaseConfig.databaseTable)"
        
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        // 2. Prepare Data
        let payload: [String: Any] = [
            "id": item.id.uuidString,
            "url": item.url?.absoluteString ?? "",
            "title": item.title,
            "summary": item.summary ?? "",
            "type": item.type.rawValue,
            "created_at": ISO8601DateFormatter().string(from: item.timestamp),
            "s3_url": imageURL,
            "tags": item.tags
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        
        // 3. Prepare Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer") // Don't return the inserted row
        request.httpBody = jsonData
        
        print("⚡️ Saving to Supabase DB...")
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        
        // 201 Created is typical for POST
        if !(200...299).contains(httpResponse.statusCode) {
            let errorMsg = String(data: responseData, encoding: .utf8) ?? "Unknown"
            print("❌ Supabase DB Save Failed: \(httpResponse.statusCode)")
            print("❌ Error: \(errorMsg)")
            throw URLError(.badServerResponse)
        }
        
        print("✅ Supabase Save Success!")
    }
    
    /// Fetches all items from 'saved_items' table.
    func fetchItems() async throws -> [SavedItem] {
        // 1. Prepare Endpoint
        // GET /rest/v1/{table}?select=*&order=created_at.desc
        let cleanURL = SupabaseConfig.url.trimmingCharacters(in: .init(charactersIn: "/"))
        let endpoint = "\(cleanURL)/rest/v1/\(SupabaseConfig.databaseTable)?select=*&order=created_at.desc"
        
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        // 2. Prepare Request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        print("⚡️ Fetching from Supabase DB...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("❌ Supabase Fetch Failed.")
            throw URLError(.badServerResponse)
        }
        
        // 3. Decode
        // We'll decode a custom struct that matches snake_case columns, then map to domain model
        let decoder = JSONDecoder()
        
        // Need to match Supabase column names exactly. 
        // Assuming columns: id, url, title, summary, type, created_at, s3_url
        struct DBRow: Codable {
            let id: String
            let url: String?
            let title: String?
            let summary: String?
            let type: String?
            let created_at: String?
            let s3_url: String?
            let tags: TagsWrapper?
        }
        
        let rows = try decoder.decode([DBRow].self, from: data)
        
        // 4. Map to SavedItem
        return rows.compactMap { row -> SavedItem? in
            guard let idUUID = UUID(uuidString: row.id),
                  let title = row.title,
                  let dateStr = row.created_at,
                  let date = ISO8601DateFormatter().date(from: dateStr) else { return nil }
            
            return SavedItem(
                id: idUUID,
                url: URL(string: row.url ?? ""),
                timestamp: date,
                type: SavedItem.ItemType(rawValue: row.type ?? "website") ?? .website,
                screenshotData: nil, // We rely on AsyncImage loading the URL
                s3Url: row.s3_url, // This will be the public Supabase Storage URL
                title: title,
                summary: row.summary,
                tags: row.tags?.values ?? []
            )
        }
    }
    /// Checks if an item with the given URL already exists.
    func checkIfURLExists(url urlString: String) async throws -> Bool {
        // 1. Prepare Endpoint
        // GET /rest/v1/{table}?url=eq.{urlString}&select=id&limit=1
        
        // Sanitize URL for query param (basic URL encoding)
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&") // Reserve these
        guard let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: allowed) else { return false }
        
        let cleanURL = SupabaseConfig.url.trimmingCharacters(in: .init(charactersIn: "/"))
        let endpoint = "\(cleanURL)/rest/v1/\(SupabaseConfig.databaseTable)?url=eq.\(encodedUrl)&select=id&limit=1"
        
        guard let serviceUrl = URL(string: endpoint) else { return false }
        
        // 2. Prepare Request
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "GET"
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        // 3. Execute
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return false // Assume false on error to avoid blocking user, or throw?
        }
        
        // 4. Decode
        // If array is not empty, item exists.
        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [Any], !jsonArray.isEmpty {
            return true
        }
        
        return false
    }
    /// Deletes an item by ID.
    func deleteItem(id: UUID) async throws {
        // DELETE /rest/v1/{table}?id=eq.{uuid}
        let cleanURL = SupabaseConfig.url.trimmingCharacters(in: .init(charactersIn: "/"))
        let endpoint = "\(cleanURL)/rest/v1/\(SupabaseConfig.databaseTable)?id=eq.\(id.uuidString)"
        
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        
        if !(200...299).contains(httpResponse.statusCode) {
             let errorMsg = String(data: responseData, encoding: .utf8) ?? "Unknown"
             print("❌ Supabase DELETE Failed: \(httpResponse.statusCode)")
             print("❌ Error: \(errorMsg)")
             throw URLError(.badServerResponse)
        }
    }
    
    /// Searches items by title or summary.
    func searchItems(query: String) async throws -> [SavedItem] {
        guard !query.isEmpty else { return try await fetchItems() }
        
        // GET /rest/v1/{table}?or=(title.ilike.*query*,summary.ilike.*query*)
        // Note: Supabase PostgREST logic for 'or' and 'ilike' can be verbose.
        // A simpler approach for MVP: Fetch all and filter locally, OR standard 'ilike'.
        // Let's try standard 'ilike' with wildcard wrapping.
        
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&")
        let q = "%\(query)%"
        guard let encodedQ = q.addingPercentEncoding(withAllowedCharacters: allowed) else { return [] }
        
        let cleanURL = SupabaseConfig.url.trimmingCharacters(in: .init(charactersIn: "/"))
        // Syntax: ?or=(title.ilike.pattern,summary.ilike.pattern)
        let endpoint = "\(cleanURL)/rest/v1/\(SupabaseConfig.databaseTable)?or=(title.ilike.\(encodedQ),summary.ilike.\(encodedQ))&order=created_at.desc"
        
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }
        
        let decoder = JSONDecoder()
        // Reusing the private DBRow struct logic would be ideal if we refactored, but for now we copy the decode logic or extract it.
        // To keep it safe, I'll essentially execute the same decoding.
        
        struct DBRow: Codable {
            let id: String
            let url: String?
            let title: String?
            let summary: String?
            let type: String?
            let created_at: String?
            let s3_url: String?
            let tags: TagsWrapper?
        }
        
        let rows = try decoder.decode([DBRow].self, from: data)
        return rows.compactMap { row -> SavedItem? in
            guard let idUUID = UUID(uuidString: row.id),
                  let title = row.title,
                  let dateStr = row.created_at,
                  let date = ISO8601DateFormatter().date(from: dateStr) else { return nil }
            
            return SavedItem(
                id: idUUID,
                url: URL(string: row.url ?? ""),
                timestamp: date,
                type: SavedItem.ItemType(rawValue: row.type ?? "website") ?? .website,
                screenshotData: nil,
                s3Url: row.s3_url,
                title: title,
                summary: row.summary,
                tags: row.tags?.values ?? []
            )
        }
    }

    // Helper to decode tags flexibly
    enum TagsWrapper: Codable {
        case array([String])
        case string(String)
        
        var values: [String] {
            switch self {
            case .array(let list): return list
            case .string(let str):
                // Handle Postgres array literal "{a,b}"
                if str.hasPrefix("{") && str.hasSuffix("}") {
                    let trim = String(str.dropFirst().dropLast())
                    return trim.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                }
                // Handle JSON string "[\"a\",\"b\"]"
                if str.hasPrefix("[") && str.hasSuffix("]") {
                    if let data = str.data(using: .utf8), let list = try? JSONDecoder().decode([String].self, from: data) {
                        return list
                    }
                }
                // Fallback: simple split or just strict string
                return [str]
            }
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let list = try? container.decode([String].self) {
                self = .array(list)
                return
            }
            if let str = try? container.decode(String.self) {
                self = .string(str)
                return
            }
            self = .array([])
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .array(let list): try container.encode(list)
            case .string(let str): try container.encode(str)
            }
        }
    }
}
