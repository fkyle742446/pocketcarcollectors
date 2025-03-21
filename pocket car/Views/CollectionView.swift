import SwiftUI

struct CollectionView: View {
    @ObservedObject var collectionManager: CollectionManager
    @State private var selectedCard: BoosterCard? = nil
    @State private var showingRarityInfo = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Titre et compteur de cartes
                    HStack {
                        Text("")
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .padding(.top, 20)

                        Button(action: {
                            showingRarityInfo.toggle()
                        }) {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                        }
                        .padding(.top, 20)
                        .padding(.leading, 8)
                        .sheet(isPresented: $showingRarityInfo) {
                            RarityInfoView(collectionManager: collectionManager)
                        }

                        Spacer()

                        Text("\(collectionManager.cards.count)/108")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 20)
                            .padding(.trailing, 16)
                    }

                    if collectionManager.cards.isEmpty {
                        EmptyCollectionView()
                    } else {
                        CollectionGridView(cards: collectionManager.cards, selectedCard: $selectedCard)
                    }
                }

                if let selectedCard = selectedCard {
                    ZoomedCardView(selectedCard: $selectedCard)
                }
            }
        }
    }
}

struct RarityInfoView: View {
    @ObservedObject var collectionManager: CollectionManager
    
    private func getCardCounts(for rarity: CardRarity) -> (collected: Int, total: Int) {
        let collectedCards = collectionManager.cards.filter { $0.card.rarity == rarity }.count
        let totalCards: Int
        switch rarity {
        case .common: totalCards = 70
        case .rare: totalCards = 20
        case .epic: totalCards = 10
        case .legendary: totalCards = 8
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
                    // Title with total progress
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
                    
                    // Cards by rarity with progress bars
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
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                    
                    // Progress
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
            
            // Progress text
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

struct EmptyCollectionView: View {
    var body: some View {
        Spacer()
        Text("Nothing to see here")
            .font(.system(size: 18, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
            .multilineTextAlignment(.center)
            .padding()
        Spacer()
    }
}

struct CardView: View {
    let card: BoosterCard
    let count: Int

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
        VStack {
            ZStack(alignment: .topTrailing) {
                // Halo effect
                RoundedRectangle(cornerRadius: 12)
                    .fill(haloColor(for: card.rarity))
                    .blur(radius: 5)
                    .frame(maxWidth: 100, maxHeight: 140)
                    .opacity(0.7)
                
                Image(card.name)
                    .resizable()
                    .aspectRatio(3 / 4, contentMode: .fit)
                    .frame(maxWidth: 100, maxHeight: 140)
                    .cornerRadius(5)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 4)

                if count > 1 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Circle().fill(Color.red))
                        .offset(x: -5, y: 5)
                }
            }

            Text(card.name)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(card.rarity == .legendary ? Color.yellow.opacity(0.2) :
                        card.rarity == .epic ? Color.purple.opacity(0.2) :
                        card.rarity == .common ? Color.white.opacity(0.2) :
                      card.rarity == .rare ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
        )
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
    }
}

struct ZoomedCardView: View {
    @Binding var selectedCard: BoosterCard?
    
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
                    // Halo effect
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
            }
        }
        .transition(.opacity)
    }
}
