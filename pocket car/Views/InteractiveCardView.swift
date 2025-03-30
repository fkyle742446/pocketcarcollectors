import SwiftUI

struct InteractiveCardView: View {
    let cardImage: String
    let rarity: CardRarity
    let cardNumber: Int
    
    var body: some View {
        HolographicCard(
            cardImage: cardImage,
            rarity: rarity,
            cardNumber: cardNumber
        )
    }
}
