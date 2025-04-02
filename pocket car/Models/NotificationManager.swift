import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    @Published var hasPermission = false
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
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
        let content = UNMutableNotificationContent()
        content.title = "New Booster Available! 🎉"
        content.body = "Your free booster is ready to be opened!"
        content.sound = .default
        content.userInfo = ["type": "booster"]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "booster_notification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
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
    
    // Gestion des notifications quand l'app est en premier plan
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // Gestion des notifications quand l'utilisateur tape dessus
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String {
            switch type {
            case "booster":
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