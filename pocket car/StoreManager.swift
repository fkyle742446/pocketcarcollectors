import Foundation
import Combine
import SwiftUI

class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    // Constantes
    private let initialFreeBoostersKey = "initialFreeBoosters"
    private let lastUnlockTimeKey = "lastUnlockTime"
    private let lastSystemUptimeKey = "lastSystemUptime"
    private let cooldownDuration: TimeInterval = 6 * 3600 // 6 heures en secondes
    
    @Published var remainingFreeBoosters: Int = 0
    @Published var nextBoosterAvailableDate: Date?
    @Published var hasDetectedTimeManipulation: Bool = false
    
    private var timer: Timer?
    private var collectionManager: CollectionManager?
    
    init() {
        // On attend que le CollectionManager soit injecté
    }
    
    func setup(with collectionManager: CollectionManager) {
        self.collectionManager = collectionManager
        checkAndSetupFreeBoosters()
        setupTimeChecks()
        
        // Observer quand l'app revient au premier plan
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    private func checkAndSetupFreeBoosters() {
        guard let collectionManager = collectionManager else { return }
        
        // Si la collection est vide, donner 4 boosters gratuits
        if collectionManager.cards.isEmpty {
            remainingFreeBoosters = 4
            UserDefaults.standard.set(remainingFreeBoosters, forKey: initialFreeBoostersKey)
        } else {
            remainingFreeBoosters = UserDefaults.standard.integer(forKey: initialFreeBoostersKey)
        }
    }
    
    private func setupTimeChecks() {
        if let lastUnlockTime = UserDefaults.standard.object(forKey: lastUnlockTimeKey) as? Date {
            self.nextBoosterAvailableDate = lastUnlockTime.addingTimeInterval(cooldownDuration)
            self.startTimer()
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateNextBoosterTime()
        }
    }
    
    private func updateNextBoosterTime() {
        guard let nextDate = nextBoosterAvailableDate else { return }
        if Date() >= nextDate {
            self.nextBoosterAvailableDate = nil
            timer?.invalidate()
        }
    }
    
    @objc private func appWillEnterForeground() {
        self.validateTimeIntegrity()
    }
    
    private func validateTimeIntegrity() {
        guard let lastUnlockTime = UserDefaults.standard.object(forKey: lastUnlockTimeKey) as? Date,
              let lastSystemUptime = UserDefaults.standard.object(forKey: lastSystemUptimeKey) as? TimeInterval else {
            return
        }
        
        let currentUptime = ProcessInfo.processInfo.systemUptime
        let expectedElapsedTime = currentUptime - lastSystemUptime
        let actualElapsedTime = Date().timeIntervalSince(lastUnlockTime)
        
        // Détecter une manipulation de temps si la différence est trop grande
        if abs(expectedElapsedTime - actualElapsedTime) > 300 { // 5 minutes de tolérance
            self.handleTimeManipulation()
        }
    }
    
    private func handleTimeManipulation() {
        hasDetectedTimeManipulation = true
        // Réinitialiser le timer avec la durée complète
        let newUnlockTime = Date()
        UserDefaults.standard.set(newUnlockTime, forKey: lastUnlockTimeKey)
        UserDefaults.standard.set(ProcessInfo.processInfo.systemUptime, forKey: lastSystemUptimeKey)
        self.nextBoosterAvailableDate = newUnlockTime.addingTimeInterval(cooldownDuration)
        self.startTimer()
    }
    
    func canOpenBooster() -> Bool {
        if remainingFreeBoosters > 0 {
            return true
        }
        
        guard let nextDate = nextBoosterAvailableDate else {
            return true
        }
        
        return Date() >= nextDate
    }
    
    func openBooster() -> Bool {
        if remainingFreeBoosters > 0 {
            remainingFreeBoosters -= 1
            UserDefaults.standard.set(remainingFreeBoosters, forKey: initialFreeBoostersKey)
            return true
        }
        
        if canOpenBooster() {
            let now = Date()
            UserDefaults.standard.set(now, forKey: lastUnlockTimeKey)
            UserDefaults.standard.set(ProcessInfo.processInfo.systemUptime, forKey: lastSystemUptimeKey)
            self.nextBoosterAvailableDate = now.addingTimeInterval(cooldownDuration)
            self.startTimer()
            return true
        }
        
        return false
    }
    
    func timeUntilNextBooster() -> TimeInterval? {
        guard let nextDate = nextBoosterAvailableDate else {
            return nil
        }
        
        let timeInterval = nextDate.timeIntervalSinceNow
        return timeInterval > 0 ? timeInterval : nil
    }
}
