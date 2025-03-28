import Foundation
import SwiftUI
import UIKit

// Card Rarity enum
enum CardRarity: String {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    case HolyT = "Holy T"
    
    var sortOrder: Int {
        switch self {
        case .common: return 0
        case .rare: return 1
        case .epic: return 2
        case .legendary: return 3
        case .HolyT: return 4
        }
    }
}

// Booster Card struct
struct BoosterCard: Identifiable, Equatable {
    let name: String
    let rarity: CardRarity
    let number: Int
    var id: String { name }
    
    static func == (lhs: BoosterCard, rhs: BoosterCard) -> Bool {
        lhs.name == rhs.name
    }
}

// Collection Manager class
class CollectionManager: ObservableObject {
    @Published var cards: [(card: BoosterCard, count: Int)] = []
    
    func isNewCard(_ card: BoosterCard) -> Bool {
        !cards.contains { $0.card.name == card.name }
    }
    
    func addCard(_ card: BoosterCard) -> Bool {
        if let index = cards.firstIndex(where: { $0.card.name == card.name }) {
            cards[index].count += 1
            return false
        } else {
            cards.append((card: card, count: 1))
            return true
        }
    }
}

// Store Manager class
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    // Constantes simples
    private let lastUnlockTimeKey = "lastUnlockTime"
    private let lastSystemUptimeKey = "lastSystemUptime"
    private let initialBoostersKey = "initialBoosters"
    private let cooldownDuration: TimeInterval = 6 * 3600 // 6 heures
    
    @Published var nextBoosterAvailableDate: Date?
    @Published var hasDetectedTimeChange: Bool = false
    @Published var remainingFreeBoosters: Int = 0
    
    private var timer: Timer?
    private var collectionManager: CollectionManager?
    
    init() {
        setupObserver()
    }
    
    private func setupObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    func setup(with collectionManager: CollectionManager) {
        self.collectionManager = collectionManager
        setupInitialBoosters()
    }
    
    private func setupInitialBoosters() {
        // Donner 4 boosters si collection vide
        if let collectionManager = collectionManager,
           collectionManager.cards.isEmpty && !UserDefaults.standard.bool(forKey: initialBoostersKey) {
            remainingFreeBoosters = 4
            UserDefaults.standard.set(true, forKey: initialBoostersKey)
        }
    }
    
    @objc private func appWillEnterForeground() {
        checkTimeIntegrity()
    }
    
    private func checkTimeIntegrity() {
        guard let lastUnlockTime = UserDefaults.standard.object(forKey: lastUnlockTimeKey) as? Date,
              let lastSystemUptime = UserDefaults.standard.object(forKey: lastSystemUptimeKey) as? TimeInterval else {
            return
        }
        
        let currentUptime = ProcessInfo.processInfo.systemUptime
        let expectedElapsedTime = currentUptime - lastSystemUptime
        let actualElapsedTime = Date().timeIntervalSince(lastUnlockTime)
        
        // Si différence de plus de 5 minutes, probable manipulation
        if abs(expectedElapsedTime - actualElapsedTime) > 300 {
            hasDetectedTimeChange = true
            resetTimer()
        }
    }
    
    private func resetTimer() {
        let now = Date()
        nextBoosterAvailableDate = now.addingTimeInterval(cooldownDuration)
        UserDefaults.standard.set(now, forKey: lastUnlockTimeKey)
        UserDefaults.standard.set(ProcessInfo.processInfo.systemUptime, forKey: lastSystemUptimeKey)
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
            return true
        }
        
        if canOpenBooster() {
            resetTimer()
            return true
        }
        
        return false
    }
    
    func timeUntilNextBooster() -> TimeInterval? {
        guard let nextDate = nextBoosterAvailableDate else {
            return nil
        }
        return max(0, nextDate.timeIntervalSinceNow)
    }
}
