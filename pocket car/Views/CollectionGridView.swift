import SwiftUI

struct CollectionGridView: View {
    let cards: [(card: BoosterCard, count: Int)]
    @Binding var selectedCard: BoosterCard?

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 100), spacing: -30)],
                spacing: -70
            ) {
                ForEach(sortedCards, id: \.card.id) { entry in
                    ZStack {
                        // Carte holographique
                        HolographicCard(
                            cardImage: entry.card.name,
                            rarity: entry.card.rarity,
                            cardNumber: entry.card.number
                        )
                        .scaleEffect(0.44)
                        .overlay(
                            // Badge de compteur si plus d'une carte
                            Group {
                                if entry.count > 1 {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Text("\(entry.count)")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                        .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2)
                                }
                            }
                            .offset(x: 40, y: -50) // Ajusté pour être dans la carte
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedCard = entry.card
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var sortedCards: [(card: BoosterCard, count: Int)] {
        cards.sorted { lhs, rhs in
            lhs.card.rarity.sortOrder > rhs.card.rarity.sortOrder
        }
    }
}

// Preview
struct CollectionGridView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionGridView(
            cards: [
                (card: BoosterCard(name: "Bugatti EB110", rarity: .rare, number: 90), count: 1),
                (card: BoosterCard(name: "Hyundai Kona Electric", rarity: .common, number: 56), count: 2),
                (card: BoosterCard(name: "BMW i3", rarity: .common, number: 59), count: 1),
                (card: BoosterCard(name: "Mercedes Classe A", rarity: .common, number: 19), count: 3),
                (card: BoosterCard(name: "Volkswagen ID.3", rarity: .common, number: 55), count: 1),
                (card: BoosterCard(name: "Ferrari LaFerrari", rarity: .epic, number: 99), count: 1),
                (card: BoosterCard(name: "McLaren P1", rarity: .legendary, number: 102), count: 1),
                (card: BoosterCard(name: "Porsche 918 Spyder", rarity: .HolyT, number: 111), count: 1)
            ],
            selectedCard: .constant(nil)
        )
        .frame(height: 600)
        .preferredColorScheme(.light)
    }
}
