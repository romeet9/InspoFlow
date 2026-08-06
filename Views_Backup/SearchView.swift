import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [SavedItem] = []
    @State private var isLoading = false
    
    // Grid Setup
    let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 20)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView("Searching...")
                        .padding(.top, 50)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .padding(.top, 50)
                } else if searchResults.isEmpty {
                    ContentUnavailableView(
                        "Search Collection",
                        systemImage: "magnifyingglass",
                        description: Text("Find inspiration by title or summary.")
                    )
                    .padding(.top, 50)
                } else {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(searchResults) { item in
                            NavigationLink(destination: DetailView(item: item)) {
                                InspoCardView(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search Designs, Apps, colors...")
            .onSubmit(of: .search) {
                Task { await performSearch() }
            }
            .onChange(of: searchText) { oldValue, newValue in
                if newValue.isEmpty {
                    searchResults = []
                } else {
                    // Optional: Live search with debounce (manual debounce omitted for brevity)
                     Task { await performSearch() }
                }
            }
        }
    }
    
    private func performSearch() async {
        guard !searchText.isEmpty else { return } // Don't search empty
        
        isLoading = true
        do {
            let items = try await SupabaseDBService.shared.searchItems(query: searchText)
            await MainActor.run {
                withAnimation {
                    self.searchResults = items
                }
                self.isLoading = false
            }
        } catch {
            print("Search Error: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
}

#Preview {
    SearchView()
}
