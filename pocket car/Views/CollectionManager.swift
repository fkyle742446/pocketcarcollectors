import SwiftUI

class CollectionManager: ObservableObject {
    // Un tableau contenant chaque carte et sa quantité
    @Published var cards: [(card: BoosterCard, count: Int)] = [] {
        didSet {
            saveCollection()
        }
    }
    
    @Published var coins: Int = 0 {
        didSet {
            UserDefaults.standard.set(coins, forKey: "userCoins")
        }
    }
    
    init() {
        loadCollection()
        coins = UserDefaults.standard.integer(forKey: "userCoins")
    }
    
    private func saveCollection() {
        let cardData = cards.map { (card, count) in
            [
                "name": card.name,
                "rarity": card.rarity.rawValue,
                "number": card.number,
                "count": count
            ]
        }
        UserDefaults.standard.set(cardData, forKey: "savedCollection")
    }
    
    private func loadCollection() {
        guard let savedData = UserDefaults.standard.array(forKey: "savedCollection") as? [[String: Any]] else {
            return
        }
        
        cards = savedData.compactMap { data in
            guard let name = data["name"] as? String,
                  let rarityString = data["rarity"] as? String,
                  let rarity = CardRarity(rawValue: rarityString),
                  let number = data["number"] as? Int,
                  let count = data["count"] as? Int else {
                return nil
            }
            
            return (card: BoosterCard(name: name, rarity: rarity, number: number), count: count)
        }
    }

    func coinValue(for rarity: CardRarity) -> Int {
        switch rarity {
        case .common: return 5
        case .rare: return 20
        case .epic: return 50
        case .legendary: return 75
        case .HolyT: return 200
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
}
