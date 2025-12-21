import SwiftUI
import SwiftData

// RENAMED TO FORCE RECOMPILE
struct GridHomeView: View {
    // Cloud Persistence
    @State private var savedItems: [SavedItem] = []
    @State private var isLoading = true
    
    // UI State
    @State private var isSelectionMode = false
    @State private var selectedItems = Set<SavedItem>()
    @State private var showIngestionSheet = false
    
    // Tag Filtering
    @State private var selectedTag: String = "All"
    @State private var showCustomTagAlert = false
    @State private var customTagInput = ""
    @State private var itemToTag: SavedItem?
    
    var allTags: [String] {
        let tags = savedItems.flatMap { $0.tags }
        let unique = Array(Set(tags)).sorted()
        return ["All"] + unique
    }
    
    var filteredItems: [SavedItem] {
        if selectedTag == "All" {
            return savedItems
        }
        return savedItems.filter { $0.tags.contains(selectedTag) }
    }
    
    // Single Column Layout
    let columns = [
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading && savedItems.isEmpty {
                    ProgressView("Loading from Cloud...")
                        .padding(.top, 50)
                } else if savedItems.isEmpty {
                    ContentUnavailableView(
                        "No Inspirations",
                        systemImage: "sparkles.rectangle.stack",
                        description: Text("Add screenshots to start building your collection.")
                    )
                    .padding(.top, 50)
                } else {

                    // Filter Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(allTags, id: \.self) { tag in
                                TagPill(tag: tag, isSelected: selectedTag == tag) {
                                    withAnimation {
                                        selectedTag = tag
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    .background(Color(.systemGroupedBackground)) // Ensure touch doesn't pass through empty space
                    .zIndex(1) // Ensure it sits above the grid if scrolling overlaps

                    LazyVGrid(columns: columns, alignment: .center, spacing: 16) { // Reduced to standard HIG spacing
                        ForEach(filteredItems) { item in
                            cardView(for: item)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .refreshable {
                await loadData()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ItemSaved"))) { _ in
                Task {
                    await loadData()
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("InspoFlow")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        if isSelectionMode {
                            Button(role: .destructive) {
                                deleteSelection()
                            } label: {
                                Text("Delete (\(selectedItems.count))")
                                    .foregroundStyle(.red)
                            }
                            .disabled(selectedItems.isEmpty)
                        } else {
                            Button {
                                startSelectionMode()
                            } label: {
                                Image(systemName: "trash")
                            }
                            
                            Button {
                                showIngestionSheet = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
                
                if isSelectionMode {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            isSelectionMode = false
                            selectedItems.removeAll()
                        }
                    }
                }
            }
            .sheet(isPresented: $showIngestionSheet) {
                 ScreenshotIngestionView(isPresented: $showIngestionSheet)
            }
            .onChange(of: showIngestionSheet) { oldValue, newValue in
                if !newValue {
                    // Sheet dismissed, refresh data
                    Task {
                        // Small delay to ensure DB write propagation
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                        await loadData()
                    }
                }
            }
            .task {
                await loadData()
            }
            .alert("Add Custom Tag", isPresented: $showCustomTagAlert) {
                TextField("Tag Name", text: $customTagInput)
                Button("Cancel", role: .cancel) { }
                Button("Add") {
                    if let item = itemToTag {
                        Task {
                            await addCustomTag(to: item, tag: customTagInput)
                        }
                    }
                }
            } message: {
                Text("Enter a new tag for this inspiration.")
            }
        }
    }
    
    // MARK: - Cloud Data
    
    private func loadData() async {
        isLoading = true
        do {
             // In a real app, you'd likely paginate or cache this better.
             let items = try await SupabaseDBService.shared.fetchItems()
             await MainActor.run {
                 withAnimation {
                     self.savedItems = items.sorted(by: { $0.timestamp > $1.timestamp })
                 }
                 self.isLoading = false
             }
        } catch {
            print("❌ Fetch Error: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private func cardView(for item: SavedItem) -> some View {
        Group {
            if isSelectionMode {
                Button {
                    toggleSelection(for: item)
                } label: {
                    InspoCardView(item: item)
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: selectedItems.contains(item) ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(selectedItems.contains(item) ? .blue : .white)
                                .background(Circle().fill(.white.opacity(0.5)))
                                .padding(10)
                        }
                        .opacity(isSelectionMode && !selectedItems.contains(item) ? 0.7 : 1.0)
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink(destination: DetailView(item: item)) {
                    InspoCardView(item: item)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        itemToTag = item
                        customTagInput = ""
                        showCustomTagAlert = true
                    } label: {
                        Label("Add Custom Tag", systemImage: "tag")
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            await deleteSingleItem(item)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func startSelectionMode() {
        isSelectionMode = true
        selectedItems.removeAll()
    }
    
    private func toggleSelection(for item: SavedItem) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }
    }
    
    private func deleteSelection() {
        Task {
            isLoading = true
            for item in selectedItems {
                do {
                    try await SupabaseDBService.shared.deleteItem(id: item.id)
                } catch {
                    print("Failed to delete \(item.id): \(error)")
                }
            }
            await loadData()
            
            await MainActor.run {
                selectedItems.removeAll()
                isSelectionMode = false
            }
        }
    }
    
    private func deleteSingleItem(_ item: SavedItem) async {
        do {
            try await SupabaseDBService.shared.deleteItem(id: item.id)
            await loadData()
        } catch {
            print("Failed to delete item: \(error)")
        }
    }
    
    private func addCustomTag(to item: SavedItem, tag: String) async {
        guard !tag.isEmpty else { return }
        // Local update
        var newTags = item.tags
        if !newTags.contains(tag) {
            newTags.append(tag)
        }
        item.tags = newTags
        
        // Optimistic UI
        if let idx = savedItems.firstIndex(where: { $0.id == item.id }) {
            savedItems[idx] = item
        }
        
        // Cloud update
        do {
            // Need a dedicated update method or just re-save. For MVP, re-save metadata.
            try await SupabaseDBService.shared.saveItem(item: item, imageURL: item.s3Url ?? "")
        } catch {
            print("Failed to add tag: \(error)")
        }
    }
}

struct TagPill: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Text(tag.capitalized)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color(.systemGray5))
            )
            .contentShape(Rectangle()) // Ensure the whole area captures the tap
            .onTapGesture {
                action()
            }
    }
}

#Preview {
    GridHomeView()
}
