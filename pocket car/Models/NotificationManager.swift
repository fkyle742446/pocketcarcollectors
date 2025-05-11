import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    @Published var hasPermission = false
    
    private let slotMachineMessages = [
        ("🎰 Feeling Lucky?", "The slot machine is calling your name! Time to spin for some serious coins?"),
        ("💰 Coin Drought?", "Your virtual pockets feeling a bit light? The slot machine might just have the cure!"),
        ("✨ Jackpot Dreams!", "Heard a rumor the slot machine is feeling generous... Worth a shot? 😉"),
        ("🚨 Boring Alert!", "Is that... boredom we detect? The slot machine offers instant excitement (and maybe coins)!"),
        ("💸 Spin to Win!", "The reels are restless! Give 'em a whirl and see if fortune favors you today.")
    ]

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkPermissionStatus()
    }
    
    private func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let authorized = settings.authorizationStatus == .authorized
                self.hasPermission = authorized
                if authorized {
                    self.scheduleSlotMachineReminderNotification()
                }
            }
        }
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.hasPermission = granted
                if granted {
                    self.scheduleSlotMachineReminderNotification()
                    // You might also want to schedule other initial notifications here if needed
                }
            }
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    func scheduleBoosterNotification(for date: Date) {
        guard hasPermission else {
            print("❌ No notification permission for booster")
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
        print("⏰ Scheduling booster notification for: \(date)")
        
        // Include seconds for more precise timing
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        if let triggerDate = trigger.nextTriggerDate() {
            print("📅 Booster - Next trigger date: \(triggerDate)")
        }
        
        let request = UNNotificationRequest(
            identifier: "booster_notification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule booster notification: \(error.localizedDescription)")
            } else {
                print("✅ Successfully scheduled booster notification")
                // Verify pending notifications
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    print("📬 Pending booster notifications: \(requests.filter { $0.identifier == "booster_notification" }.count)")
                }
            }
        }
    }

    func scheduleDailyQuestNotification(for date: Date) {
        guard hasPermission else {
            print("❌ No notification permission for daily quest")
            return
        }

        // Cancel any existing daily quest notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_quest_notification"])

        let content = UNMutableNotificationContent()
        content.title = "Daily Quest Ready! ⚔️" 
        content.body = "Your daily quest is waiting for you. Complete it for rewards!" 
        content.sound = .default
        content.userInfo = ["type": "daily_quest"] 

        print("⏰ Scheduling daily quest notification for: \(date)")

        let timeInterval = date.timeIntervalSinceNow
        guard timeInterval > 0 else {
            print("ℹ️ Daily quest notification date is in the past. Not scheduling. Date: \(date), Now: \(Date())")
            return
        }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        if let triggerDate = trigger.nextTriggerDate() {
            print("📅 Daily Quest - Next trigger date: \(triggerDate)")
        } else {
            print("⚠️ Daily Quest - Could not determine next trigger date from components: \(components)")
        }
        
        let request = UNNotificationRequest(
            identifier: "daily_quest_notification",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule daily quest notification: \(error.localizedDescription)")
            } else {
                print("✅ Successfully scheduled daily quest notification")
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                     print("📬 Pending daily quest notifications: \(requests.filter { $0.identifier == "daily_quest_notification" }.count)")
                }
            }
        }
    }

    func scheduleSlotMachineReminderNotification() {
        guard hasPermission else {
            print("❌ No notification permission for slot machine reminder.")
            return
        }

        let identifier = "slot_machine_reminder"
        // Check if a reminder is already scheduled to avoid re-scheduling unless necessary
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            if requests.contains(where: { $0.identifier == identifier }) {
                print("ℹ️ Slot machine reminder already scheduled. Skipping.")
                return
            }

            // Pick a random funny message
            guard let randomMessage = self.slotMachineMessages.randomElement() else { return }

            let content = UNMutableNotificationContent()
            content.title = randomMessage.0 // Title
            content.body = randomMessage.1  // Body
            content.sound = .default
            content.userInfo = ["type": "slot_machine_reminder"]

            // Schedule for 48 hours from now, and repeat
            // Note: Minimum repeat interval is 60 seconds.
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 48 * 60 * 60, repeats: true) 
            // For testing, you might want a shorter interval, e.g., 60 seconds:
            // let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: true)


            print("⏰ Scheduling slot machine reminder. First one in 48 hours, then repeating.")

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule slot machine reminder: \(error.localizedDescription)")
                } else {
                    print("✅ Successfully scheduled slot machine reminder.")
                     UNUserNotificationCenter.current().getPendingNotificationRequests { pendingRequests in
                        if let scheduledReminder = pendingRequests.first(where: { $0.identifier == identifier }) {
                            if let timeTrigger = scheduledReminder.trigger as? UNTimeIntervalNotificationTrigger,
                               let nextTriggerDate = timeTrigger.nextTriggerDate() {
                                print("🎰 Slot machine reminder next trigger date: \(nextTriggerDate)")
                            }
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
            case "daily_quest":
                print("⚔️ Opening daily quest view from notification")
                NotificationCenter.default.post(name: .openDailyQuestView, object: nil)
            case "slot_machine_reminder":
                print("🎰 Opening slot machine view from notification")
                NotificationCenter.default.post(name: .openSlotMachineView, object: nil)
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
    static let openDailyQuestView = Notification.Name("openDailyQuestView")
    static let openSlotMachineView = Notification.Name("openSlotMachineView")
}
