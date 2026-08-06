import SwiftUI
import SwiftData

struct GridHomeView: View {
    // Cloud Persistence
    @State private var savedItems: [SavedItem] = []
    @State private var isLoading = true
    
    // Theme
    @AppStorage("isDarkMode") private var isDarkMode = false
    
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
    
    // Flexible Grid - Apple Style
    let columns = [
        GridItem(.adaptive(minimum: 160, maximum: .infinity), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                // Filter Bar Section
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allTags, id: \.self) { tag in
                            TagPill(tag: tag, isSelected: selectedTag == tag) {
                                withAnimation(.snappy) {
                                    selectedTag = tag
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                
                if isLoading && savedItems.isEmpty {
                    VStack {
                        ProgressView()
                            .controlSize(.large)
                        Text("Loading Library...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else if savedItems.isEmpty {
                    ContentUnavailableView(
                        "No Items",
                        systemImage: "square.stack.3d.up.slash",
                        description: Text("Tap + to add your first inspiration.")
                    )
                    .padding(.top, 50)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredItems) { item in
                            cardView(for: item)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // Primary Action: Add
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showIngestionSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
                
                // Secondary Action: More Menu (Select, Theme)
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section {
                            Button {
                                startSelectionMode()
                            } label: {
                                Label("Select", systemImage: "checkmark.circle")
                            }
                        }
                        
                        Section {
                            Button {
                                ThemeTransition.toggleTheme(isDarkMode: $isDarkMode)
                            } label: {
                                Label(isDarkMode ? "Light Mode" : "Dark Mode", systemImage: isDarkMode ? "sun.max" : "moon")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                // Selection Mode Toolbar
                if isSelectionMode {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            isSelectionMode = false
                            selectedItems.removeAll()
                        }
                    }
                    
                    ToolbarItem(placement: .bottomBar) {
                        HStack {
                            Button(role: .destructive) {
                                deleteSelection()
                            } label: {
                                Text("Delete")
                                    .foregroundStyle(.red)
                            }
                            .disabled(selectedItems.isEmpty)
                            Spacer()
                            Text("\(selectedItems.count) Selected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }
            }
            .refreshable {
                await loadData()
            }
        }
        .sheet(isPresented: $showIngestionSheet) {
             ScreenshotIngestionView(isPresented: $showIngestionSheet)
        }
        .onChange(of: showIngestionSheet) { oldValue, newValue in
            if !newValue {
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await loadData()
                }
            }
        }
        .task {
            await loadData()
        }
        // Custom Tag Alert
        .alert("Add Tag", isPresented: $showCustomTagAlert) {
            TextField("Tag Name", text: $customTagInput)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if let item = itemToTag {
                    Task { await addCustomTag(to: item, tag: customTagInput) }
                }
            }
        } message: {
            Text("Create a new tag to organize your collection.")
        }
        // Observe external saves
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ItemSaved"))) { _ in
            Task { await loadData() }
        }
    }
    
    // MARK: - Logic & Components
    
    private func loadData() async {
        isLoading = true
        do {
             let items = try await SupabaseDBService.shared.fetchItems()
             await MainActor.run {
                 withAnimation(.smooth) {
                     self.savedItems = items.sorted(by: { $0.timestamp > $1.timestamp })
                 }
                 self.isLoading = false
             }
        } catch {
            print("❌ Fetch Error: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
    
    @ViewBuilder
    private func cardView(for item: SavedItem) -> some View {
        Group {
            if isSelectionMode {
                Button {
                    toggleSelection(for: item)
                } label: {
                    InspoCardView(item: item)
                        .overlay(alignment: .topTrailing) {
                            if selectedItems.contains(item) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                    .background(Circle().fill(.white))
                                    .padding(8)
                            } else {
                                Image(systemName: "circle")
                                    .font(.title3)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .shadow(radius: 2)
                                    .padding(8)
                            }
                        }
                        .scaleEffect(selectedItems.contains(item) ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedItems.contains(item))
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
                        Label("Add Tag", systemImage: "tag")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        Task { await deleteSingleItem(item) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } preview: {
                    InspoCardView(item: item)
                }
            }
        }
    }
    
    private func startSelectionMode() {
        withAnimation {
            isSelectionMode = true
            selectedItems.removeAll()
        }
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
                try? await SupabaseDBService.shared.deleteItem(id: item.id)
            }
            await loadData()
            await MainActor.run {
                withAnimation {
                    selectedItems.removeAll()
                    isSelectionMode = false
                }
            }
        }
    }
    
    private func deleteSingleItem(_ item: SavedItem) async {
        try? await SupabaseDBService.shared.deleteItem(id: item.id)
        await loadData()
    }
    
    private func addCustomTag(to item: SavedItem, tag: String) async {
        guard !tag.isEmpty else { return }
        var newTags = item.tags
        if !newTags.contains(tag) { newTags.append(tag) }
        item.tags = newTags
        if let idx = savedItems.firstIndex(where: { $0.id == item.id }) {
            savedItems[idx] = item
        }
        try? await SupabaseDBService.shared.saveItem(item: item, imageURL: item.s3Url ?? "")
    }
}

// MARK: - Native Filter Pill
struct TagPill: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.system(.subheadline, design: .default, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? .white : .primary)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.primary) // Black in light, White in dark (Apple standard)
                    } else {
                        Capsule()
                            .fill(Color(.secondarySystemFill)) // Subtle system fill
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GridHomeView()
}
