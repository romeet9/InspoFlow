import SwiftUI
import SwiftData

struct InspoTimelineView: View {
    @Query(sort: \SavedItem.timestamp, order: .reverse) private var savedItems: [SavedItem]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    if savedItems.isEmpty {
                        ContentUnavailableView(
                            "No History",
                            systemImage: "clock.arrow.circlepath",
                            description: Text("Your timeline is empty.\nStart capturing inspiration!")
                        )
                        .padding(.top, 100)
                    } else {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedItems, id: \.key) { date, items in
                                Section(header: TimelineHeader(text: date)) {
                                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                        HStack(alignment: .top, spacing: 16) {
                                            // 1. Timeline Track (Line + Dot)
                                            TimelineTrack(isLast: index == items.count - 1)
                                            
                                            // 2. Card Content
                                            NavigationLink(destination: DetailView(item: item)) {
                                                TimelineCard(item: item)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .padding(.bottom, 24)
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Timeline")
        }
    }
    
    // Grouping Logic
    private var groupedItems: [(key: String, value: [SavedItem])] {
        let grouped = Dictionary(grouping: savedItems) { item in
            let calendar = Calendar.current
            if calendar.isDateInToday(item.timestamp) {
                return "Today"
            } else if calendar.isDateInYesterday(item.timestamp) {
                return "Yesterday"
            } else {
                return item.timestamp.formatted(date: .abbreviated, time: .omitted)
            }
        }
        
        return grouped.sorted { (lhs, rhs) in
            guard let lDate = lhs.value.first?.timestamp, let rDate = rhs.value.first?.timestamp else { return false }
            return lDate > rDate
        }
    }
}

// MARK: - Components

struct TimelineHeader: View {
    let text: String
    
    var body: some View {
        HStack {
            Text(text.uppercased())
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.05), radius: 2)
                )
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color(.systemGroupedBackground)
                .opacity(0.95)
        )
    }
}

struct TimelineTrack: View {
    let isLast: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // The Dot
            Circle()
                .fill(Color.accentColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color(.systemGroupedBackground), lineWidth: 2)
                )
            
            // The Line
            if !isLast {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 12) // Fixed width for alignment
        .padding(.top, 10) // Align dot with card top
    }
}

struct TimelineCard: View {
    let item: SavedItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Cover (Full Width Layout)
            if let data = item.screenshotData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                HStack {
                    Spacer()
                    Image(systemName: item.themeIcon)
                        .font(.system(size: 40))
                        .foregroundStyle(item.themeColor)
                    Spacer()
                }
                .frame(height: 100)
                .background(item.themeColor.opacity(0.1))
            }
            
            // Info Block
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                HStack {
                    if let url = item.url?.host() {
                        Label(url.replacingOccurrences(of: "www.", with: ""), systemImage: "link")
                    } else {
                        Label("Screenshot", systemImage: "photo")
                    }
                    
                    Spacer()
                    
                    Text(item.timestamp, format: .dateTime.hour().minute())
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.6),
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}
