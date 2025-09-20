import UIKit
import UserNotifications
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register background tasks
        BackgroundTaskManager.shared.registerTasks()
        BackgroundTaskManager.shared.scheduleAppRefresh()

        // Request notification authorization (optional UI alerts). For silent push only, this isn't required, but we can still request for debugging.
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
        application.registerForRemoteNotifications()
        return true
    }

    // Called for silent push (content-available: 1)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Trigger a refresh from shared defaults
        let store = LogStore()
        store.load()
        completionHandler(.newData)
    }
}
