import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var screenshotService: ScreenshotService
    @Query(sort: \SavedItem.timestamp, order: .reverse) private var savedItems: [SavedItem]

    @State private var isSelectionMode = false
    @State private var selectedItems = Set<SavedItem>()
    @State private var showIngestionSheet = false

    // Standard Grid items
    let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if savedItems.isEmpty {
                    ContentUnavailableView(
                        "No Inspirations",
                        systemImage: "sparkles.rectangle.stack",
                        description: Text("Add screenshots or links to start building your collection.")
                    )
                    .padding(.top, 50)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(savedItems) { item in
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
                                            // Dim unselected items slightly?
                                            .opacity(isSelectionMode && !selectedItems.contains(item) ? 0.7 : 1.0)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    NavigationLink(destination: DetailView(item: item)) {
                                        InspoCardView(item: item)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            modelContext.delete(item)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
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
            // Standard Sheet Presentation
            .sheet(isPresented: $showIngestionSheet) {
                 ScreenshotIngestionView(isPresented: $showIngestionSheet)
            }
        }
        }
    
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
        withAnimation {
            for item in selectedItems {
                modelContext.delete(item)
            }
            selectedItems.removeAll()
            isSelectionMode = false
        }
    }
}


#Preview {
    HomeView()
}
