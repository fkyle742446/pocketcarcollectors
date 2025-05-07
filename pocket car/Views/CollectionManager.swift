import SwiftUI

enum MilestoneIdentifier: String, CaseIterable, Codable {
    case progress25 = "progress25"
    case progress50 = "progress50"
    case progress75 = "progress75"
    case progress100 = "progress100"
    // Add more milestones here if needed

    var rewardCoins: Int {
        switch self {
        case .progress25: return 200
        case .progress50: return 300 // Or a special item/booster
        case .progress75: return 400
        case .progress100: return 500 // Or a special item/booster
        }
    }

    // You can add other reward types here, e.g., boosters
    // var rewardBoosters: Int {
    //     switch self {
    //     case .progress50: return 1
    //     default: return 0
    //     }
    // }
}

class CollectionManager: ObservableObject {
    static let shared = CollectionManager()
    
    // Un tableau contenant chaque carte et sa quantité
    private let currentVersion = 1
    private let versionKey = "com.pocketcarcollectors.collection.version"
    private let collectionKey = "com.pocketcarcollectors.collection.data"
    private let coinsKey = "com.pocketcarcollectors.collection.coins"
    private let backupKey = "com.pocketcarcollectors.collection.backup"
    private let claimedMilestonesKey = "com.pocketcarcollectors.collection.claimedMilestones"

    @Published var cards: [(card: BoosterCard, count: Int)] = [] {
        didSet {
            saveCollection()
        }
    }
    
    @Published var coins: Int = 0 {
        didSet {
            UserDefaults.standard.set(coins, forKey: coinsKey)
        }
    }
    
    @Published var claimedMilestones: Set<MilestoneIdentifier> = [] {
        didSet {
            saveClaimedMilestones()
        }
    }
    
    init() {
        print("Initializing CollectionManager...")
        print("Checking for existing data...")
        
        if let existingData = UserDefaults.standard.dictionary(forKey: collectionKey) {
            print("Found existing data with version: \(existingData["version"] ?? "unknown")")
        } else {
            print("No existing data found")
        }
        
        migrateDataIfNeeded()
        loadCollection()
        coins = UserDefaults.standard.integer(forKey: coinsKey)
        
        loadClaimedMilestones()
        
        print("Loaded collection with \(cards.count) cards and \(claimedMilestones.count) claimed milestones.")
        validateLoadedData()
    }
    
    private func validateLoadedData() {
        // Vérifier si les données sont cohérentes
        if cards.isEmpty {
            // Essayer de restaurer depuis la sauvegarde
            if let backup = UserDefaults.standard.dictionary(forKey: backupKey) {
                print("Attempting to restore from backup...")
                restoreFromBackup()
            }
        }
    }
    
    private func migrateDataIfNeeded() {
        let savedVersion = UserDefaults.standard.integer(forKey: versionKey)
        print("Current data version: \(savedVersion)")
        
        // Créer une sauvegarde avant migration
        if let existingData = UserDefaults.standard.dictionary(forKey: collectionKey) {
            print("Creating backup before migration...")
            UserDefaults.standard.set(existingData, forKey: backupKey)
        }
        
        if savedVersion == 0 {
            print("Migrating from legacy format...")
            migrateFromLegacyFormat()
        }
        
        // Mettre à jour la version après migration réussie
        UserDefaults.standard.set(currentVersion, forKey: versionKey)
        print("Migration complete. New version: \(currentVersion)")
    }
    
    private func restoreFromBackup() {
        guard let backup = UserDefaults.standard.dictionary(forKey: backupKey),
              let cardData = backup["cards"] as? [[String: Any]] else {
            print("No valid backup found")
            return
        }
        
        cards = cardData.compactMap { data in
            guard let name = data["name"] as? String,
                  let rarityString = data["rarity"] as? String,
                  let rarity = CardRarity(rawValue: rarityString),
                  let number = data["number"] as? Int,
                  let count = data["count"] as? Int else {
                return nil
            }
            
            return (card: BoosterCard(name: name, rarity: rarity, number: number), count: count)
        }
        
        print("Restored \(cards.count) cards from backup")
        saveCollection() // Sauvegarder immédiatement les données restaurées
    }
    
    func saveCollection() {
        let cardData = cards.map { (card, count) in
            [
                "name": card.name,
                "rarity": card.rarity.rawValue,
                "number": card.number,
                "count": count,
                "version": currentVersion
            ]
        }
        
        let saveData: [String: Any] = [
            "version": currentVersion,
            "cards": cardData,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        UserDefaults.standard.set(saveData, forKey: collectionKey)
        print("Saved collection with \(cards.count) cards")
    }
    
    private func loadCollection() {
        print("Loading collection...")
        guard let savedData = UserDefaults.standard.dictionary(forKey: collectionKey),
              let cardData = savedData["cards"] as? [[String: Any]] else {
            print("No saved collection found, attempting migration...")
            migrateFromLegacyFormat()
            return
        }
        
        cards = cardData.compactMap { data in
            guard let name = data["name"] as? String,
                  let rarityString = data["rarity"] as? String,
                  let rarity = CardRarity(rawValue: rarityString),
                  let number = data["number"] as? Int,
                  let count = data["count"] as? Int else {
                return nil
            }
            
            return (card: BoosterCard(name: name, rarity: rarity, number: number), count: count)
        }
        
        print("Successfully loaded \(cards.count) cards")
    }
    
    private func migrateFromLegacyFormat() {
        // Essayer de charger les données depuis différents formats possibles
        if let legacyData = UserDefaults.standard.array(forKey: collectionKey) as? [[String: Any]] {
            // Sauvegarder une copie de sécurité des anciennes données
            UserDefaults.standard.set(legacyData, forKey: "\(collectionKey)_backup")
            
            // Tenter de convertir les anciennes données
            cards = legacyData.compactMap { data in
                guard let name = data["name"] as? String,
                      let rarityString = data["rarity"] as? String,
                      let rarity = CardRarity(rawValue: rarityString),
                      let number = data["number"] as? Int,
                      let count = data["count"] as? Int else {
                    return nil
                }
                
                return (card: BoosterCard(name: name, rarity: rarity, number: number), count: count)
            }
            
            // Sauvegarder immédiatement dans le nouveau format
            saveCollection()
        }
    }
    
    func coinValue(for rarity: CardRarity) -> Int {
        switch rarity {
        case .common: return 5
        case .rare: return 20
        case .epic: return 50
        case .legendary: return 75
        case .HolyT: return 200
        case .Season1: return 1000
        }
    }
    
    // Add function to check if card is new
    func isNewCard(_ card: BoosterCard) -> Bool {
        !cards.contains { $0.card.name == card.name && $0.card.rarity == card.rarity }
    }

    // Ajoute une carte à la collection
    @discardableResult
    func addCard(_ card: BoosterCard) -> Bool {
        let isNew = isNewCard(card)
        
        if let index = cards.firstIndex(where: { $0.card.name == card.name && $0.card.rarity == card.rarity }) {
            // Si la carte existe déjà, incrémentez la quantité
            cards[index].count += 1
        } else {
            // Sinon, ajoutez une nouvelle entrée
            cards.append((card: card, count: 1))
        }
        
        return isNew
    }
    
    func sellCard(_ card: BoosterCard) -> Bool {
        guard let index = cards.firstIndex(where: { $0.card.name == card.name && $0.card.rarity == card.rarity }) else {
            return false
        }
        
        coins += coinValue(for: card.rarity)
        
        if cards[index].count > 1 {
            cards[index].count -= 1
        } else {
            cards.remove(at: index)
        }
        
        return true
    }
    
    private func loadClaimedMilestones() {
        if let data = UserDefaults.standard.data(forKey: claimedMilestonesKey) {
            if let decodedMilestones = try? JSONDecoder().decode(Set<MilestoneIdentifier>.self, from: data) {
                self.claimedMilestones = decodedMilestones
                print("Loaded \(claimedMilestones.count) claimed milestones.")
                return
            }
        }
        self.claimedMilestones = []
        print("No claimed milestones found or error decoding, initialized to empty set.")
    }

    private func saveClaimedMilestones() {
        if let encoded = try? JSONEncoder().encode(claimedMilestones) {
            UserDefaults.standard.set(encoded, forKey: claimedMilestonesKey)
            print("Saved \(claimedMilestones.count) claimed milestones.")
        } else {
            print("Error encoding claimed milestones.")
        }
    }

    func claimMilestone(_ milestone: MilestoneIdentifier) {
        guard !claimedMilestones.contains(milestone) else {
            print("Milestone \(milestone.rawValue) already claimed.")
            return
        }

        // Add coins or other rewards
        coins += milestone.rewardCoins
        // if milestone.rewardBoosters > 0 {
        //     StoreManager.shared.boosters += milestone.rewardBoosters
        // }
        
        claimedMilestones.insert(milestone)
        // saveClaimedMilestones() // Called by didSet of claimedMilestones
        
        print("Milestone \(milestone.rawValue) claimed. Coins awarded: \(milestone.rewardCoins). New coin total: \(coins).")
        NotificationCenter.default.post(name: .coinsDidUpdate, object: nil) // Notify UI about coin change
        NotificationCenter.default.post(name: .milestoneClaimed, object: milestone) // Notify UI a milestone was claimed
    }
}

extension Notification.Name {
    static let milestoneClaimed = Notification.Name("milestoneClaimed")
}
