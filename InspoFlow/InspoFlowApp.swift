import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    application.registerForRemoteNotifications()
    return true
  }

  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
      Auth.auth().setAPNSToken(deviceToken, type: .unknown)
  }

  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
      if Auth.auth().canHandleNotification(userInfo) {
          completionHandler(.noData)
          return
      }
      completionHandler(.newData)
  }
}

@main
struct InspoFlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SavedItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    #if DEBUG
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    #else
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    #endif
    @StateObject private var screenshotService = ScreenshotService()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    RootTabView()
                        .transition(.opacity)
                } else {
                    OnboardingContainerView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: hasCompletedOnboarding)
            .preferredColorScheme(.light) // Enforce the Light Theme
            .environmentObject(screenshotService) // Inject Globally
            .onAppear {
                // Inject Context and Start Service
                screenshotService.setContext(sharedModelContainer.mainContext)
                screenshotService.requestPermission()
            }
            .onOpenURL { url in
                AuthService.shared.handleUrl(url) { result in
                    switch result {
                    case .success(_):
                        print("Email Link Auth Success")
                    case .failure(let error):
                        print("Email Link Auth Error: \(error.localizedDescription)")
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
