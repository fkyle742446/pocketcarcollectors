import SwiftUI

enum MilestoneIdentifier: String, CaseIterable, Codable {
    case progress04 = "progress04"
    case progress25 = "progress25"
    case progress50 = "progress50"
    case progress75 = "progress75"
    case progress100 = "progress100"
    // Add more milestones here if needed

    var rewardCoins: Int {
        switch self {
        case .progress04: return 0
        case .progress25: return 200
        case .progress50: return 0 // No coins if a card is given
        case .progress75: return 500 // Was 0, now gets coins from old progress100
        case .progress100: return 0  // Was 500, now gets 0 as card is the reward
        }
    }

    var rewardCard: BoosterCard? {
        switch self {
        case .progress50:
            return BoosterCard(name: "Ferrari FXX-K", rarity: .legendary, number: 233)
        case .progress75:
            return nil // Was Ferrari LaFerrari, now no card
        case .progress100:
            return BoosterCard(name: "Ferrari LaFerrari Holy Trinity", rarity: .Season1, number: 253) // Was nil, now gets Ferrari LaFerrari
        default:
            return nil
        }
    }

    var rewardBoosters: Int {
        switch self {
        case .progress04: return 5
        default: return 0
        }
    }
}

// You should populate this with the actual EX cards definition.
// This helps in finding the EX equivalent.
// If your EX cards don't follow a strict naming/numbering convention
// related to their base cards, this list is crucial.
let allGameEXCards: [BoosterCard] = [
    // Example:
    // BoosterCard(name: "Porsche 911 Carrera", rarity: .holographicEX, number: 1),
    // BoosterCard(name: "Ferrari F40", rarity: .holographicEX, number: 2),
    // ... add all your EX cards here
    // For now, if this list is empty, findEXEquivalent will try a convention.
]

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
            NotificationCenter.default.post(name: .collectionDidChange, object: nil)
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
        case .holographicEX: return 150
        }
    }
    
    func isNewCard(_ card: BoosterCard) -> Bool {
        !cards.contains { $0.card.name == card.name && $0.card.rarity == card.rarity }
    }

    func addCard(_ card: BoosterCard) -> Bool {
        let isNew = isNewCard(card)
        
        if let index = cards.firstIndex(where: { $0.card.name == card.name && $0.card.rarity == card.rarity }) {
            cards[index].count += 1
        } else {
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

    // IMPORTANT: This function makes assumptions. Adjust it based on how your EX cards are defined.
    // Option 1: Check against a predefined list of EX cards.
    // Option 2: Assume EX card has same name and number, just .holographicEX rarity.
    func findEXEquivalent(for baseCard: BoosterCard) -> BoosterCard? {
        // Prioritize checking the explicit list if populated
        if !allGameEXCards.isEmpty {
            // This assumes EX cards might have a modified name (e.g., "My Car EX") or a different number.
            // You'll need a more robust way to link baseCard to its EX version if names/numbers change significantly.
            // For now, let's assume if an EX card shares the *base name part* and is EX.
            // This is a naive example, you'll need to refine this matching logic.
            return allGameEXCards.first { exCard in
                // Example: If base is "Porsche 911" and EX is "Porsche 911 EX"
                // or if they share a common root identifier not directly in BoosterCard struct (e.g. a car model ID)
                // For simplicity, let's assume for now the EX version has the same name and number.
                exCard.name == baseCard.name && exCard.number == baseCard.number && exCard.rarity == .holographicEX
            }
        } else {
            // Fallback: Assume EX card has the same name and number, just .holographicEX rarity.
            // This is a strong assumption.
            print("Warning: `allGameEXCards` is empty. Falling back to name/number convention for EX card identification.")
            return BoosterCard(name: baseCard.name, rarity: .holographicEX, number: baseCard.number)
        }
        // If you have a more structured way to define EX cards (e.g. they are listed in Card.allCards or similar)
        // you should use that to find the EX version.
    }

    enum CombinationResult {
        case success(BoosterCard) // The EX card obtained
        case failure
        case notEnoughCards
        case alreadyEX
        case noEXEquivalent
    }

    func combineCards(for baseCard: BoosterCard, numberOfCardsToSacrifice: Int) -> CombinationResult {
        guard baseCard.rarity != .holographicEX else {
            return .alreadyEX
        }

        guard let cardInCollection = cards.first(where: { $0.card == baseCard }),
              cardInCollection.count > numberOfCardsToSacrifice, // Must have more than sacrificed to keep one
              numberOfCardsToSacrifice > 0 else {
            return .notEnoughCards
        }

        guard let exEquivalent = findEXEquivalent(for: baseCard) else {
            // If you have a list like `allGameCards` that includes EX cards,
            // you can check here if `BoosterCard(name: baseCard.name, rarity: .holographicEX, number: baseCard.number)`
            // actually exists in that list.
            // For now, we assume if findEXEquivalent returns nil, it means no mapping defined.
            print("No EX equivalent defined or found for \(baseCard.name)")
            return .noEXEquivalent
        }

        // Remove sacrificed cards
        if let index = cards.firstIndex(where: { $0.card == baseCard }) {
            cards[index].count -= numberOfCardsToSacrifice
            if cards[index].count == 0 { // Should not happen if logic is correct (always keep 1)
                cards.remove(at: index)
                 print("Error: Combined last card, should always keep one. Card: \(baseCard.name)")
            }
        } else {
            // Should not happen if cardInCollection was found
            print("Error: Base card not found in collection during sacrifice. Card: \(baseCard.name)")
            return .notEnoughCards // Or a more specific error
        }

        // Calculate success chance (10% per card sacrificed, max 100% for 10 cards)
        let successChance = min(Double(numberOfCardsToSacrifice) * 0.1, 1.0)
        let randomRoll = Double.random(in: 0.0...1.0)

        if randomRoll <= successChance {
            _ = addCard(exEquivalent) // Add the new EX card
            print("Combination SUCCESS for \(baseCard.name) -> \(exEquivalent.name) (\(exEquivalent.rarity))")
            NotificationCenter.default.post(name: .cardCombinationSuccess, object: exEquivalent)
            return .success(exEquivalent)
        } else {
            print("Combination FAILED for \(baseCard.name)")
            NotificationCenter.default.post(name: .cardCombinationFailure, object: baseCard)
            return .failure
        }
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

        if milestone.rewardCoins > 0 {
            coins += milestone.rewardCoins
        }
        
        if let cardToReward = milestone.rewardCard {
            addCard(cardToReward)
            print("Milestone \(milestone.rawValue) awarded card: \(cardToReward.name).")
        }
        
        if milestone.rewardBoosters > 0 {
            StoreManager.shared.boosters += milestone.rewardBoosters
            print("Milestone \(milestone.rawValue) awarded \(milestone.rewardBoosters) boosters.")
            // Assuming StoreManager handles saving its own state for boosters
        }
        
        claimedMilestones.insert(milestone)
        
        print("Milestone \(milestone.rawValue) claimed. New coin total: \(coins).")
        NotificationCenter.default.post(name: .milestoneClaimed, object: milestone)
    }
}

extension Notification.Name {
    static let milestoneClaimed = Notification.Name("milestoneClaimed")
    static let collectionDidChange = Notification.Name("collectionDidChange")
    static let cardCombinationSuccess = Notification.Name("cardCombinationSuccess")
    static let cardCombinationFailure = Notification.Name("cardCombinationFailure")
}
