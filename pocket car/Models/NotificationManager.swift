import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    @Published var hasPermission = false
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkPermissionStatus()
    }
    
    // Check current permission status
    private func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.hasPermission = granted
            }
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    func scheduleBoosterNotification(for date: Date) {
        guard hasPermission else {
            print("❌ No notification permission")
            return
        }
        
        // Cancel any existing booster notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["booster_notification"])
        
        let content = UNMutableNotificationContent()
        content.title = "New Booster Available! 🎉"
        content.body = "Your free booster is ready to be opened!"
        content.sound = .default
        content.userInfo = ["type": "booster"]
        
        // Add debugging information
        print("⏰ Scheduling notification for: \(date)")
        
        // Include seconds for more precise timing
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        if let triggerDate = trigger.nextTriggerDate() {
            print("📅 Next trigger date: \(triggerDate)")
        }
        
        let request = UNNotificationRequest(
            identifier: "booster_notification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("✅ Successfully scheduled notification")
                // Verify pending notifications
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    print("📬 Pending notifications: \(requests.count)")
                    for request in requests {
                        if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                           let nextTrigger = trigger.nextTriggerDate() {
                            print("📌 Pending notification scheduled for: \(nextTrigger)")
                        }
                    }
                }
            }
        }
    }
    
    func scheduleReviewNotification() {
        // On planifie la notification de review après 3 jours d'utilisation
        let content = UNMutableNotificationContent()
        content.title = "Enjoying Pocket Car? ⭐️"
        content.body = "We'd love to hear your feedback! Tap to rate the app."
        content.sound = .default
        content.userInfo = ["type": "review"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3 * 24 * 60 * 60, repeats: false)
        let request = UNNotificationRequest(
            identifier: "review_notification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // Improve foreground notification handling
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📱 Notification received while app is in foreground")
        completionHandler([.banner, .sound, .badge])
    }
    
    // Gestion des notifications quand l'utilisateur tape dessus
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("👆 User tapped notification with userInfo: \(userInfo)")
        
        if let type = userInfo["type"] as? String {
            switch type {
            case "booster":
                print("🎁 Opening booster view from notification")
                NotificationCenter.default.post(name: .openBoosterView, object: nil)
            case "review":
                AppUpdateChecker.shared.openAppStore()
            default:
                break
            }
        }
        
        completionHandler()
    }
}

// Extension pour les noms de notification
extension Notification.Name {
    static let openBoosterView = Notification.Name("openBoosterView")
}
