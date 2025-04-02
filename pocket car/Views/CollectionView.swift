import SwiftUI
import AVFoundation

struct CollectionView: View {
    @ObservedObject var collectionManager: CollectionManager
    @State private var selectedCard: BoosterCard? = nil
    @State private var showingRarityInfo = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.white, Color(.systemGray5)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    HStack {
                        Spacer()
                        Text("\(collectionManager.cards.count)/250")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                        Text("•")
                            .foregroundColor(.gray)
                        HStack(spacing: 4) {
                            Text("\(collectionManager.coins)")
                                .font(.system(size: 16, weight: .medium))
                            Image("coin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 20)

                    if collectionManager.cards.isEmpty {
                        EmptyCollectionView()
                    } else {
                        CollectionGridView(cards: collectionManager.cards, selectedCard: $selectedCard)
                    }
                }

                if let selectedCard = selectedCard {
                    ZoomedCardView(selectedCard: $selectedCard, collectionManager: collectionManager)
                }
            }
        }
    }
}

struct EmptyCollectionView: View {
    var body: some View {
        Spacer()
        Text("Nothing to see here")
            .font(.system(size: 18, design: .rounded))
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .padding()
        Spacer()
    }
}

struct CardView: View {
    let card: BoosterCard
    let count: Int

    private func rarityColor(for rarity: CardRarity) -> Color {
        switch rarity {
        case .common:
            return Color.gray
        case .rare:
            return Color.blue
        case .epic:
            return Color.purple
        case .legendary:
            return Color(red: 1, green: 0.84, blue: 0)
        case .HolyT:
            return Color(white: 0.8)
        }
    }
    
    private func rarityGradient(for rarity: CardRarity) -> LinearGradient {
        switch rarity {
        case .common:
            return LinearGradient(
                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .rare:
            return LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .epic:
            return LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .legendary:
            return LinearGradient(
                colors: [Color(red: 1, green: 0.84, blue: 0).opacity(0.3),
                        Color(red: 1, green: 0.84, blue: 0).opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .HolyT:
            return LinearGradient(
                colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private func rarityBadge(for rarity: CardRarity) -> String {
        switch rarity {
        case .common: return "COMMON"
        case .rare: return "RARE"
        case .epic: return "EPIC"
        case .legendary: return "LEGENDARY"
        case .HolyT: return "HOLY"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // Card Image with border
                Image(card.name)
                    .resizable()
                    .aspectRatio(3 / 4, contentMode: .fit)
                    .frame(maxWidth: 100, maxHeight: 140)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        rarityColor(for: card.rarity).opacity(0.8),
                                        rarityColor(for: card.rarity).opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: rarityColor(for: card.rarity).opacity(0.3), radius: 5, x: 0, y: 4)

                // Count badge if more than 1
                if count > 1 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.red)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                        )
                        .offset(x: -5, y: 5)
                }
            }

            // Rarity badge
            Text(rarityBadge(for: card.rarity))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(rarityColor(for: card.rarity))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )

            // Card name
            Text(card.name)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(rarityGradient(for: card.rarity))
                )
                .shadow(color: rarityColor(for: card.rarity).opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

struct RarityInfoView: View {
    @ObservedObject var collectionManager: CollectionManager
    
    private func getCardCounts(for rarity: CardRarity) -> (collected: Int, total: Int) {
        let collectedCards = collectionManager.cards.filter { $0.card.rarity == rarity }.count
        let totalCards: Int
        switch rarity {
        case .common: totalCards = 100
        case .rare: totalCards = 75
        case .epic: totalCards = 50
        case .legendary: totalCards = 25
        case .HolyT: totalCards = 3
        }
        return (collectedCards, totalCards)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.black, Color.gray.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    VStack(spacing: 8) {
                        Text("Collection Progress")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                        
                        let totalProgress = Double(collectionManager.cards.count) / 111.0
                        Text("\(Int(totalProgress * 100))% Complete")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        ForEach([CardRarity.HolyT, .legendary, .epic, .rare, .common], id: \.self) { rarity in
                            let counts = getCardCounts(for: rarity)
                            VStack(spacing: 10) {
                                HStack {
                                    Image(systemName: rarityIcon(for: rarity))
                                        .foregroundColor(rarityColor(for: rarity))
                                        .font(.system(size: 16))
                                    
                                    Text(rarity.rawValue.uppercased())
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(rarityColor(for: rarity))
                                    
                                    Spacer()
                                    
                                    Text("\(rarityDropRate(for: rarity))")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                CollectionProgressBar(
                                    rarity: rarity,
                                    collected: counts.collected,
                                    total: counts.total
                                )
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(rarityColor(for: rarity).opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(12)
                    
                    Spacer()
                }
                .padding(12)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func rarityIcon(for rarity: CardRarity) -> String {
        switch rarity {
        case .common: return "circle.fill"
        case .rare: return "star.fill"
        case .epic: return "sparkles"
        case .legendary: return "crown.fill"
        case .HolyT: return "bolt.fill"
        }
    }
    
    private func rarityColor(for rarity: CardRarity) -> Color {
        switch rarity {
        case .common: return .white
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return Color(red: 1, green: 0.84, blue: 0)
        case .HolyT: return Color(white: 0.8)
        }
    }
    
    private func rarityDropRate(for rarity: CardRarity) -> String {
        switch rarity {
        case .common: return "70%"
        case .rare: return "25%"
        case .epic: return "10%"
        case .legendary: return "2%"
        case .HolyT: return "0.1%"
        }
    }
    
    init(collectionManager: CollectionManager) {
        self._collectionManager = ObservedObject(wrappedValue: collectionManager)
    }
}

struct CollectionProgressBar: View {
    let rarity: CardRarity
    let collected: Int
    let total: Int
    
    private func progressColor(for rarity: CardRarity) -> Color {
        switch rarity {
        case .common:
            return .gray
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    progressColor(for: rarity),
                                    progressColor(for: rarity).opacity(0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(collected) / CGFloat(total))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .frame(height: 12)
            
            HStack {
                Text("\(collected)/\(total)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("\(Int((Double(collected)/Double(total)) * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(progressColor(for: rarity))
            }
        }
    }
}

struct ZoomedCardView: View {
    @Binding var selectedCard: BoosterCard?
    @ObservedObject var collectionManager: CollectionManager
    
    private func haloColor(for rarity: CardRarity) -> Color {
        switch rarity {
        case .common:
            return Color.white
        case .rare:
            return Color.blue
        case .epic:
            return Color.purple
        case .legendary:
            return Color(red: 1, green: 0.84, blue: 0)
        case .HolyT:
            return Color(white: 0.8)
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        selectedCard = nil
                    }
                }
            
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(haloColor(for: selectedCard?.rarity ?? .common))
                        .blur(radius: 20)
                        .frame(width: 280, height: 400)
                        .opacity(0.7)
                    
                    HolographicCard(
                        cardImage: selectedCard?.name ?? "",
                        rarity: selectedCard?.rarity ?? .common,
                        cardNumber: selectedCard?.number ?? 0
                    )
                    .scaledToFit()
                    .frame(width: 300, height: 420)
                    .cornerRadius(16)
                }
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Text(selectedCard?.name ?? "")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                if let card = selectedCard {
                    Button(action: {
                        print("Sell button tapped")
                        HapticManager.shared.impact(style: .heavy)
                        if collectionManager.sellCard(card) {
                            AudioManager.shared.playSellSound()
                            selectedCard = nil
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("Sell for")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            Text("\(collectionManager.coinValue(for: card.rarity))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.gray)
                            Image("coin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                                
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.yellow.opacity(0.5), .orange.opacity(0.5)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(
                                    LinearGradient(
                                        colors: [.yellow.opacity(0.3), .orange.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1
                                )
                                .blur(radius: 2)
                        )
                    }
                }
            }
        }
        .transition(.opacity)
    }
}
