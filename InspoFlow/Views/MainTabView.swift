import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var screenshotService: ScreenshotService
    
    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                // Tab 1: Home
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                // Tab 2: Timeline
                InspoTimelineView()
                    .tabItem {
                        Label("Timeline", systemImage: "clock.fill")
                    }
                
                // Tab 3: Profile
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.circle.fill")
                    }
            }
            
            // Toast Overlay Removed
        }
        .sheet(isPresented: $screenshotService.showIngestionSheet) {
            ScreenshotIngestionView(
                isPresented: $screenshotService.showIngestionSheet,
                externalImage: screenshotService.latestScreenshot
            )
        }
    }
}

#Preview {
    MainTabView()
}
