import SwiftUI

struct BoosterSummaryView: View {
    let cards: [BoosterCard]
    let onDismiss: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCard: BoosterCard? = nil
    @State private var glowRotationAngle: Double = 0
    
    var body: some View {
        VStack {
            Text("Opening Summary")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .padding(.top, 30)
            
            Rectangle()
                .fill(LinearGradient(
                    colors: [.purple, .blue, .green],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 2)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: -150) {
                HStack(spacing: -120) {
                    ForEach(cards.prefix(3), id: \.number) { card in
                        CardSummaryView(card: card)
                            .onTapGesture {
                                selectedCard = card
                            }
                    }
                }
                .padding(.horizontal)
                
                HStack(spacing: -120) {
                    ForEach(cards.suffix(2), id: \.number) { card in
                        CardSummaryView(card: card)
                            .onTapGesture {
                                selectedCard = card
                            }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "house.fill")
                        .font(.system(size: 16))
                    Text("Home")
                        .font(.headline)
                }
                .foregroundColor(.gray)
                .frame(width: 120)
                .frame(height: 50)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .glow(
                                fill: .angularGradient(
                                    colors: [.blue, .purple, .red, .orange, .yellow, .blue],
                                    center: .center,
                                    startAngle: .degrees(glowRotationAngle),
                                    endAngle: .degrees(glowRotationAngle + 360)
                                ),
                                lineWidth: 2.0,
                                blurRadius: 4.0
                            )
                            .opacity(0.4)
                        
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white)
                    }
                )
            }
            .padding(.bottom, 30)
        }
        .background(Color.white)
        .preferredColorScheme(.light)
        .overlay(
            Group {
                if let selectedCard = selectedCard {
                    ZStack {
                        Color.black
                            .opacity(0.9)
                            .ignoresSafeArea()
                            .onTapGesture {
                                self.selectedCard = nil
                            }
                        
                        HolographicCard(
                            cardImage: selectedCard.name,
                            rarity: selectedCard.rarity,
                            cardNumber: selectedCard.number
                        )
                        .frame(width: 250, height: 350)
                    }
                }
            }
        )
        .onAppear {
            withAnimation(
                .linear(duration: 10)
                .repeatForever(autoreverses: false)
            ) {
                glowRotationAngle = 360
            }
        }
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
        .scaleEffect(0.44)
    }
}

struct PocketCardView: View {
    let card: BoosterCard
    
    var body: some View {
        VStack(spacing: 2) {
            Text(card.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(card.rarity == .common ? Color(.systemGray) : rarityColor(for: card.rarity))
            Text(card.rarity.rawValue.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(rarityColor(for: card.rarity))
            
            HolographicCard(
                cardImage: card.name,
                rarity: card.rarity,
                cardNumber: card.number
            )
            .frame(width: 40, height: 40)
            
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
