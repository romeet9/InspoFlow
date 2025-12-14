import Foundation
import SwiftData

@Model
final class SavedItem {
    @Attribute(.unique) var id: UUID
    var url: URL?
    var timestamp: Date
    var type: ItemType
    @Attribute(.externalStorage) var screenshotData: Data?
    var title: String
    var summary: String?

    init(id: UUID = UUID(), url: URL? = nil, timestamp: Date = Date(), type: ItemType = .website, screenshotData: Data? = nil, title: String = "Untitled", summary: String? = nil) {
        self.id = id
        self.url = url
        self.timestamp = timestamp
        self.type = type
        self.screenshotData = screenshotData
        self.title = title
        self.summary = summary
    }
    
    enum ItemType: String, Codable {
        case website
        case app
        case other
    }
}

import SwiftUI

extension SavedItem {
    var themeColor: Color {
        // Pastel Palette
        let colors: [Color] = [
            Color(red: 0.68, green: 0.78, blue: 0.81), // Soft Blue
            Color(red: 0.76, green: 0.69, blue: 0.88), // Soft Purple
            Color(red: 0.47, green: 0.87, blue: 0.47), // Soft Green
            Color(red: 0.99, green: 0.99, blue: 0.59), // Soft Yellow
            Color(red: 1.00, green: 0.72, blue: 0.70), // Soft Pink
            Color(red: 1.00, green: 0.85, blue: 0.76)  // Soft Orange
        ]
        let index = abs(id.hashValue) % colors.count
        return colors[index]
    }
    
    var themeIcon: String {
        // Abstract Shapes
        let icons = [
            "circle.fill",
            "square.fill",
            "triangle.fill",
            "capsule.fill",
            "hexagon.fill",
            "star.fill",
            "rhombus.fill"
        ]
        let index = abs(id.hashValue) % icons.count
        return icons[index]
    }
}
