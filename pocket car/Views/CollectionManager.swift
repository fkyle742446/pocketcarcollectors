import SwiftUI

class CollectionManager: ObservableObject {
    // Un tableau contenant chaque carte et sa quantité
    @Published var cards: [(card: BoosterCard, count: Int)] = []

    // Add function to check if card is new
    func isNewCard(_ card: BoosterCard) -> Bool {
        !cards.contains { $0.card.name == card.name && $0.card.rarity == card.rarity }
    }

    // Ajoute une carte à la collection
    @discardableResult
    func addCard(_ card: BoosterCard) -> Bool {
        let isNew = isNewCard(card)
        
        DispatchQueue.main.async {
            if let index = self.cards.firstIndex(where: { $0.card.name == card.name && $0.card.rarity == card.rarity }) {
                // Si la carte existe déjà, incrémentez la quantité
                self.cards[index].count += 1
            } else {
                // Sinon, ajoutez une nouvelle entrée
                self.cards.append((card: card, count: 1))
            }
        }
        
        return isNew
    }
}
