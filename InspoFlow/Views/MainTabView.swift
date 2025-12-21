import SwiftUI

// RENAMED TO FORCE RECOMPILE
struct RootTabView: View {
    @EnvironmentObject var screenshotService: ScreenshotService
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Home (Using New GridHomeView)
            GridHomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Tab 2: Timeline (Disabled)
//            InspoTimelineView()
//                .tabItem {
//                    Label("Timeline", systemImage: "clock.fill")
//                }
//                .tag(1)
            
            // Tab 3: Search
            SearchView() 
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(2)
            
            // Tab 4: Profile
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(3)
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
    RootTabView()
        .environmentObject(ScreenshotService())
}
