import SwiftUI
import AVFoundation
import AudioToolbox

struct CollectionView: View {
    @ObservedObject var collectionManager: CollectionManager
    @State private var selectedCard: BoosterCard? = nil
    @State private var showingRarityInfo = false
    @State private var showingCompleteView = true
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private var viewSize: ViewSize {
        horizontalSizeClass == .compact ? .compact : .regular
    }
    
    private var allSlots: [Int] {
        [254, 253, 252, 251] + Array((1...250).reversed())
    }
    
    private var collectedCards: [(card: BoosterCard, count: Int)] {
        collectionManager.cards.sorted { $0.card.number > $1.card.number }
    }
    
    private func getCard(for number: Int) -> (card: BoosterCard, count: Int)? {
        return collectionManager.cards.first { $0.card.number == number }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.white, Color(.systemGray5)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    HStack {
                        CustomToggleButton(isOn: $showingCompleteView)
                            .padding(.leading, 16)
                        
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
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.fixed(120), spacing: 8),
                                GridItem(.fixed(120), spacing: 8),
                                GridItem(.fixed(120), spacing: 8)
                            ],
                            spacing: 8
                        ) {
                            if showingCompleteView {
                                ForEach(collectedCards, id: \.card.number) { cardData in
                                    CardView(card: cardData.card, count: cardData.count)
                                        .onTapGesture {
                                            HapticManager.shared.impact(style: .light)
                                            AudioManager.shared.playCardTapSound()
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedCard = cardData.card
                                            }
                                        }
                                }
                            } else {
                                ForEach(allSlots, id: \.self) { number in
                                    if let cardData = getCard(for: number) {
                                        CardView(card: cardData.card, count: cardData.count)
                                            .onTapGesture {
                                                HapticManager.shared.impact(style: .light)
                                                AudioManager.shared.playCardTapSound()
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    selectedCard = cardData.card
                                                }
                                            }
                                    } else {
                                        EmptySlotView(number: number)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                }
                .frame(maxWidth: viewSize == .compact ? .infinity : min(geometry.size.width * 0.8, 800))
                .frame(maxWidth: .infinity)

                if let selectedCard = selectedCard {
                    ZoomedCardView(selectedCard: $selectedCard, collectionManager: collectionManager)
                }
            }
        }
    }
}

struct EmptySlotView: View {
    let number: Int
    
    var body: some View {
        ZStack {
            // Base layer avec un effet plus premium
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemGray6),
                            Color(.systemGray5).opacity(0.8),
                            Color(.systemGray6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 180)
                .overlay(
                    // Effet de glassmorphism subtil
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.white.opacity(0.3), location: 0),
                                    .init(color: Color.white.opacity(0.1), location: 0.3),
                                    .init(color: Color.white.opacity(0.05), location: 0.7),
                                    .init(color: Color.white.opacity(0.0), location: 1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            
            // Effet de profondeur supplémentaire
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.black.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .blur(radius: 0.5)
            
            Text(number > 250 ? "?" : "\(number)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(.systemGray3),
                            Color(.systemGray4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 1)
                .overlay(
                    Text(number > 250 ? "?" : "\(number)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                        .offset(x: 0.5, y: 0.5)
                        .mask(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .white, location: 0.3),
                                    .init(color: .clear, location: 1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
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
            return Color.black
        case .Season1:
            return Color.red
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
                
                case .Season1:
                    return LinearGradient(
                        colors: [Color.red.opacity(0.3), Color.red.opacity(0.1)],
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
        case .Season1: return "SEASON"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
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
                                        rarityColor(for: card.rarity).opacity(card.rarity == .HolyT ? 0.9 : 0.8),
                                        rarityColor(for: card.rarity).opacity(card.rarity == .HolyT ? 0.7 : 0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: card.rarity == .HolyT ? 2.5 : 2
                            )
                    )
                    .shadow(color: rarityColor(for: card.rarity).opacity(card.rarity == .HolyT ? 0.5 : 0.3), radius: card.rarity == .HolyT ? 8 : 5, x: 0, y: 4)

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
                .shadow(color: rarityColor(for: card.rarity).opacity(card.rarity == .HolyT ? 0.4 : 0.2), radius: card.rarity == .HolyT ? 10 : 8, x: 0, y: 4)
        )
    }
}

struct CustomToggleButton: View {
    @Binding var isOn: Bool
    private let width: CGFloat = 45
    private let height: CGFloat = 28
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7, blendDuration: 0)) {
                isOn.toggle()
                HapticManager.shared.impact(style: .light)
                AudioManager.shared.playToggleSound()
            }
        }) {
            ZStack {
                Capsule()
                    .fill(isOn ?
                        LinearGradient(
                            colors: [.yellow.opacity(0.5), .orange.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color(.systemGray5), Color(.systemGray5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width, height: height)
                
                Capsule()
                    .strokeBorder(isOn ? Color.orange.opacity(0) : Color(.systemGray4), lineWidth: 0.5)
                    .frame(width: width, height: height)
                
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
                    .frame(width: height - 3, height: height - 3)
                    .offset(x: isOn ? 8 : -8)
                    .animation(.interpolatingSpring(stiffness: 500, damping: 35), value: isOn)
            }
            .buttonStyle(.plain)
        }
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
        case .Season1: totalCards = 1
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
        case .Season1: return "bolt.fill"
        }
    }
    
    private func rarityColor(for rarity: CardRarity) -> Color {
        switch rarity {
        case .common: return .white
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return Color(red: 1, green: 0.84, blue: 0)
        case .HolyT: return Color(white: 0.8)
        case .Season1: return .red
        }
    }
    
    private func rarityDropRate(for rarity: CardRarity) -> String {
        switch rarity {
        case .common: return "70%"
        case .rare: return "25%"
        case .epic: return "8%%"
        case .legendary: return "1%"
        case .HolyT: return "0.1%"
        case .Season1: return "0.01%"
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
        case .Season1:
            return .red
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
            return Color.black
        case .Season1:
            return Color.red
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            
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
                    }
                }
            }
        }
        .transition(.opacity)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCard = nil
            }
        }
    }
}
