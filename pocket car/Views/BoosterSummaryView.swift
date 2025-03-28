import SwiftUI

struct BoosterSummaryView: View {
    let cards: [BoosterCard]
    let onDismiss: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("Opening Summary")
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(Color(.systemGray))
                .padding(.top, 30)
            
            Spacer()
            
            // First row - 3 cards
            HStack(spacing: 12) {
                ForEach(cards.prefix(3), id: \.number) { card in
                    HolographicCard(
                        cardImage: card.name,
                        rarity: card.rarity,
                        cardNumber: card.number
                    )
                    .frame(width: 40, height: 56)
                }
            }
            .padding(.horizontal)
            
            // Second row - 2 cards
            HStack(spacing: 12) {
                ForEach(cards.suffix(2), id: \.number) { card in
                    HolographicCard(
                        cardImage: card.name,
                        rarity: card.rarity,
                        cardNumber: card.number
                    )
                    .frame(width: 40, height: 56)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Next")
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.ultraThinMaterial)
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .background(Color(.systemBackground))
    }
}

struct CardSummaryView: View {
    let card: BoosterCard
    
    var body: some View {
        HolographicCard(
            cardImage: card.name,
            rarity: card.rarity,
            cardNumber: card.number
        )
        .frame(width: 40, height: 40)
    }
}

struct PocketCardView: View {
    let card: BoosterCard
    
    var body: some View {
        VStack(spacing: 2) {
            // Card Name and Rarity
            Text(card.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(card.rarity == .common ? Color(.systemGray) : rarityColor(for: card.rarity))
            Text(card.rarity.rawValue.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(rarityColor(for: card.rarity))
            
            // Card Image
            HolographicCard(
                cardImage: card.name,
                rarity: card.rarity,
                cardNumber: card.number
            )
            .frame(width: 40, height: 40)
            
            // Card Number
            Text("N° \(card.number)/111")
                .font(.system(size: 10))
                .foregroundStyle(Color(.systemGray))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(card.rarity == .rare ? Color.blue.opacity(0.1) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    card.rarity == .rare ? Color.blue.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
    }
    
    private func rarityColor(for rarity: CardRarity) -> Color {
        switch rarity {
        case .common:
            return Color(.systemGray)
        case .rare:
            return .blue
        case .epic:
            return .purple
        case .legendary:
            return Color(red: 1, green: 0.84, blue: 0)
        case .HolyT:
            return Color(white: 0.8)
        }
    }
}

struct BoosterSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        BoosterSummaryView(
            cards: [
                BoosterCard(name: "Bugatti EB110", rarity: .rare, number: 90),
                BoosterCard(name: "Hyundai Kona Electric", rarity: .common, number: 56),
                BoosterCard(name: "BMW i3", rarity: .common, number: 59),
                BoosterCard(name: "Mercedes Classe A", rarity: .common, number: 19),
                BoosterCard(name: "Volkswagen ID.3", rarity: .common, number: 55)
            ],
            onDismiss: {}
        )
    }
}
