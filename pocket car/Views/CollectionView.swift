import SwiftUI
import AVFoundation
import AudioToolbox

// New struct for the Rainbow Toggle Button
struct RainbowToggleButton: View {
    @Binding var isOn: Bool
    let label: String
    let iconName: String?

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
                HapticManager.shared.impact(style: .light)
                AudioManager.shared.playToggleSound() // Assuming you have a generic toggle sound
            }
        }) {
            HStack(spacing: 4) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 14)) // Adjusted icon size
                }
                Text(label)
                    .font(.system(size: 12, weight: .semibold)) // Adjusted font weight
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12) // Adjusted padding
            .frame(height: 28) // Match CustomToggleButton height
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: isOn ? [Color.red, Color.orange, Color.yellow, Color.green, Color.blue, Color.purple] : [Color(.systemGray3)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(isOn ? 0.5 : 0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

struct CollectionView: View {
    @ObservedObject var collectionManager: CollectionManager
    @State private var selectedCard: BoosterCard? = nil
    @State private var showingRarityInfo = false
    @State private var showingCompleteView = true
    @State private var showEXCards: Bool = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private var viewSize: ViewSize {
        horizontalSizeClass == .compact ? .compact : .regular
    }
    
    private var allSlots: [Int] {
        [254, 253, 252, 251] + Array((1...250).reversed())
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
                    HStack(spacing: 8) {
                        CustomToggleButton(isOn: $showingCompleteView)
                            .disabled(showEXCards)
                            .opacity(showEXCards ? 0.5 : 1.0)
                        
                        RainbowToggleButton(isOn: $showEXCards, label: "EX", iconName: "sparkles")
                        
                        Spacer()
                        
                        Text("\(collectionManager.cards.count)/505")
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
                    }
                    .padding(.horizontal, 16)
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
                            if showEXCards {
                                ForEach(collectionManager.cards.filter { $0.card.rarity == .holographicEX }.sorted(by: { $0.card.number > $1.card.number }), id: \.card.number) { cardData in
                                    CardView(card: cardData.card, count: cardData.count)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            HapticManager.shared.impact(style: .light)
                                            AudioManager.shared.playCardTapSound()
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedCard = cardData.card
                                            }
                                        }
                                }
                            } else {
                                if showingCompleteView {
                                    ForEach(collectionManager.cards.filter { $0.card.rarity != .holographicEX }.sorted(by: { $0.card.number > $1.card.number }), id: \.card.number) { cardData in
                                        CardView(card: cardData.card, count: cardData.count)
                                            .contentShape(Rectangle())
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
                                            if cardData.card.rarity == .holographicEX {
                                                EmptySlotView(number: number)
                                            } else {
                                                CardView(card: cardData.card, count: cardData.count)
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        HapticManager.shared.impact(style: .light)
                                                        AudioManager.shared.playCardTapSound()
                                                        withAnimation(.easeInOut(duration: 0.2)) {
                                                            selectedCard = cardData.card
                                                        }
                                                    }
                                            }
                                        } else {
                                            EmptySlotView(number: number)
                                        }
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
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemGray6),
                            Color(.systemGray5).opacity(0.8),
                            Color(.systemGray6)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 120, height: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.white.opacity(0.3), location: 0),
                                    .init(color: Color.white.opacity(0.1), location: 0.3),
                                    .init(color: Color.white.opacity(0.05), location: 0.7),
                                    .init(color: Color.white.opacity(0.0), location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
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
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.black.opacity(0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
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
                                startPoint: .top,
                                endPoint: .bottom
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

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HolographicCard(
                cardImage: card.name,
                rarity: card.rarity,
                cardNumber: card.number,
                isInteractive: false
            )
            .scaleEffect(120 / 250)
            .frame(width: 120, height: 180)

            if count > 1 {
                Text("\(count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(5)
                    .background(
                        Circle()
                            .fill(Color.red)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    )
                    .offset(x: -10, y: 10)
                    .alignmentGuide(.top) { d in d[.top] }
                    .alignmentGuide(.trailing) { d in d[.trailing] }
            }
        }
        .contentShape(Rectangle())
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
        case .holographicEX: totalCards = 5
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
                        ForEach([CardRarity.holographicEX, CardRarity.HolyT, CardRarity.Season1, CardRarity.legendary, CardRarity.epic, CardRarity.rare, CardRarity.common], id: \.self) { rarity in
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
        case .holographicEX: return "burst.fill"
        }
    }
    
    private func rarityColor(for rarity: CardRarity) -> Color {
        switch rarity {
        case .common: return .white.opacity(0.7)
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return Color(red: 1, green: 0.84, blue: 0)
        case .HolyT: return Color(white: 0.9)
        case .Season1: return .red
        case .holographicEX: return .cyan
        }
    }
    
    private func rarityDropRate(for rarity: CardRarity) -> String {
        switch rarity {
        case .common: return "70%"
        case .rare: return "25%"
        case .epic: return "8%"
        case .legendary: return "1%"
        case .HolyT: return "0.1%"
        case .Season1: return "0.01%"
        case .holographicEX: return "0.5%"
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
        case .holographicEX:
            return .cyan
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

struct CombinationResultPopupView: View {
    enum ResultType {
        case success(BoosterCard)
        case failure(sacrificedCardName: String, sacrificedCount: Int)
    }

    let resultType: ResultType
    let onClose: () -> Void

    @State private var appears: Bool = false
    @State private var glowRotationAngle: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                // Header
                ZStack {
                    Text(headerTitle)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(UIColor.label)) // Standard label color like milestone
                        .padding(.vertical, 20)
                    
                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                    }
                    .padding(.trailing, 20)
                }
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemGray6).opacity(0.8))
                
                Divider()

                // Content
                VStack(spacing: 20) {
                    switch resultType {
                    case .success(let obtainedCard):
                        // Use MilestoneRewardCardView for displaying the card
                        MilestoneRewardCardView(card: obtainedCard)
                            .frame(height: 350 * 0.75) // Match milestone card display size
                            .scaleEffect(0.75)
                            .padding(.top, 10)

                        Text("Successfully combined into:")
                            .font(.system(size: 18, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .padding(.horizontal)
                        Text("\(obtainedCard.name) EX")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(obtainedCard.rarity == .holographicEX ? .cyan : headerColorForResult)


                    case .failure(let sacrificedCardName, let sacrificedCount):
                        Image(systemName: "xmark.shield.fill") // Alternative failure icon
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.red.opacity(0.7))
                            .padding(.top, 30) // More space for icon

                        Text("Combination Failed")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(UIColor.label))
                            .padding(.top, 10)
                        
                        Text("You lost \(sacrificedCount)x \(sacrificedCardName).\nBetter luck next time!")
                            .font(.system(size: 16))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.bottom, 10) // Space before button
                    }
                    
                    Button(action: onClose) {
                        Text(buttonText)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background(buttonGradient) // Dynamic gradient
                            .cornerRadius(12)
                            .shadow(color: buttonShadowColor.opacity(0.4), radius: 8, y: 4)
                    }
                    .padding(.horizontal, 25)
                    .padding(.bottom, 25)
                }
            }
            .frame(maxWidth: 340) // Consistent with MilestoneRewardPopup
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)

                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            AngularGradient( // Use the same stroke as MilestoneRewardPopup
                                colors: [.blue.opacity(0.7), .purple.opacity(0.7), .red.opacity(0.7), .orange.opacity(0.7), .yellow.opacity(0.7), .blue.opacity(0.7)],
                                center: .center,
                                startAngle: .degrees(glowRotationAngle),
                                endAngle: .degrees(glowRotationAngle + 360)
                            ),
                            lineWidth: 3
                        )
                        .blur(radius: 5)
                        .opacity(0.6) // Match milestone glow opacity
                }
            )
            .cornerRadius(25) // Match milestone corner radius
            .scaleEffect(appears ? 1 : 0.9)
            .opacity(appears ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1), value: appears) // Match milestone animation
            .onAppear {
                // Sound is played by ZoomedCardView based on success/failure
                withAnimation {
                    appears = true
                }
                withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
                    glowRotationAngle = 360
                }
            }
        }
        .zIndex(10)
    }

    // Helper properties for dynamic styling, aligned with MilestoneRewardPopup
    private var headerTitle: String {
        switch resultType {
        case .success: return "Combination Success!"
        case .failure: return "Combination Failed"
        }
    }
    
    private var headerColorForResult: Color { // Renamed to avoid conflict if MilestonePopup's `headerColor` was different
        switch resultType {
        case .success: return .cyan // Specific for EX cards
        case .failure: return .red
        }
    }
    
    private var buttonText: String {
        switch resultType {
        case .success: return "Awesome!" // Like MilestoneRewardPopup
        case .failure: return "Too bad!"
        }
    }
    
    private var buttonGradient: LinearGradient {
        switch resultType {
        case .success: // Match Milestone "Awesome!" button
            return LinearGradient(gradient: Gradient(colors: [Color.orange, Color.yellow]), startPoint: .leading, endPoint: .trailing)
        case .failure: // A more subdued gradient for failure
            return LinearGradient(gradient: Gradient(colors: [Color(.systemGray2), Color(.systemGray3)]), startPoint: .leading, endPoint: .trailing)
        }
    }

    private var buttonShadowColor: Color {
        switch resultType {
        case .success: return .orange // Match Milestone "Awesome!" button shadow
        case .failure: return .gray
        }
    }
}

struct CombinationSuspenseView: View {
    @State private var shimmerAngle: Angle = .degrees(0)
    @State private var sparklesOpacity: Double = 0.5
    @State private var scaleEffect: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.75).edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                ZStack {
                    Image(systemName: "sparkles.square.filled.on.square")
                        .font(.system(size: 80))
                        .foregroundColor(.cyan.opacity(0.3))
                        .blur(radius: 3)
                    
                    Image(systemName: "sparkles.square.filled.on.square")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(gradient: Gradient(colors: [.cyan, .blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .rotationEffect(shimmerAngle)
                        .scaleEffect(scaleEffect)
                        .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 0)

                    // Sparkles effect
                    ForEach(0..<10) { _ in
                        Circle()
                            .fill(Color.white.opacity(Double.random(in: 0.3...0.8)))
                            .frame(width: CGFloat.random(in: 3...8), height: CGFloat.random(in: 3...8))
                            .offset(x: CGFloat.random(in: -60...60), y: CGFloat.random(in: -60...60))
                            .opacity(sparklesOpacity)
                            .scaleEffect(CGFloat.random(in: 0.5...1.2))
                    }
                }
                .onAppear {
                    withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                        shimmerAngle = .degrees(360)
                    }
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(0.1)) {
                        sparklesOpacity = sparklesOpacity == 0.5 ? 1.0 : 0.5
                        scaleEffect = scaleEffect == 1.0 ? 1.1 : 1.0
                    }
                }

                Text("Combining cards...")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
            }
        }
        .zIndex(15) // Ensure it's above ZoomedCardView content but below result popup if layered
    }
}

struct ZoomedCardView: View {
    @Binding var selectedCard: BoosterCard?
    @ObservedObject var collectionManager: CollectionManager
    @State private var isSelling = false
    
    @State private var showCombinationResultPopup = false
    @State private var combinationPopupResultType: CombinationResultPopupView.ResultType? = nil

    @State private var isProcessingCombination: Bool = false

    @State private var canCombine: Bool = false
    @State private var maxSacrificeCount: Int = 0

    private let hapticSuccess = UINotificationFeedbackGenerator()
    private let hapticFailure = UINotificationFeedbackGenerator()

    @State private var rainbowGlowAngle: Double = 0

    private func haloColor(for rarity: CardRarity) -> Color {
        switch rarity {
        case .common:
            return Color.white.opacity(0.7)
        case .rare:
            return Color.blue.opacity(0.7)
        case .epic:
            return Color.purple.opacity(0.7)
        case .legendary:
            return Color(red: 1, green: 0.84, blue: 0).opacity(0.7)
        case .HolyT:
            return Color.black.opacity(0.7)
        case .Season1:
            return Color.red.opacity(0.7)
        case .holographicEX:
            return Color.cyan.opacity(0.6)
        }
    }
    
    private func updateCombinationState() {
        guard let currentCard = selectedCard, currentCard.rarity != .holographicEX else {
            canCombine = false
            return
        }

        if let cardData = collectionManager.cards.first(where: { $0.card == currentCard }) {
            if cardData.count >= 2 { // Need at least 1 to sacrifice, 1 to keep
                if collectionManager.findEXEquivalent(for: currentCard) != nil {
                     maxSacrificeCount = min(cardData.count - 1, 10) // Max 10 to sacrifice
                     canCombine = maxSacrificeCount > 0
                     return
                }
            }
        }
        canCombine = false
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
                .onTapGesture {
                    if !isProcessingCombination {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCard = nil
                        }
                    }
                }
            
            VStack(spacing: 15) { // Reduced spacing a bit
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(haloColor(for: selectedCard?.rarity ?? .common))
                        .blur(radius: 20)
                        .frame(width: 280, height: 400)
                        .opacity(0.7)
                    
                    HolographicCard(
                        cardImage: selectedCard?.name ?? "",
                        rarity: selectedCard?.rarity ?? .common,
                        cardNumber: selectedCard?.number ?? 0,
                        isInteractive: true
                    )
                    .scaledToFit()
                    .frame(width: 300, height: 420) // Slightly adjusted for better fit
                    .cornerRadius(16)
                }
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Text(selectedCard?.name ?? "")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 5) // Add some space
                
                if let card = selectedCard {
                    // Sell Button
                    Button(action: {
                        HapticManager.shared.impact(style: .heavy)
                        isSelling = true
                        if collectionManager.sellCard(card) {
                            AudioManager.shared.playSound(named: "sell_card_success")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                selectedCard = nil
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("Sell for")
                            Text("\(collectionManager.coinValue(for: card.rarity))")
                                .fontWeight(.bold)
                            Image("coin")
                                .resizable().scaledToFit().frame(width: 20, height: 20)
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.vertical, 12).padding(.horizontal, 20)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 15).fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                                RoundedRectangle(cornerRadius: 15).stroke(
                                    LinearGradient(colors: [.yellow.opacity(0.5), .orange.opacity(0.5)], startPoint: .leading, endPoint: .trailing),
                                    lineWidth: 1
                                )
                            }
                        )
                    }
                    .disabled(isSelling || isProcessingCombination) // Disable if processing
                    .padding(.bottom, 5) // Space before combine button

                    // Combine Button - New Design
                    if canCombine && card.rarity != .holographicEX {
                        Button(action: {
                            guard let baseCard = selectedCard, maxSacrificeCount > 0 else { return }
                            
                            isProcessingCombination = true // Start suspense
                            HapticManager.shared.impact(style: .heavy)
                            AudioManager.shared.playSound(named: "combine_start_ritual", volume: 0.6) // A new sound for starting

                            // Delay for suspense animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { // Adjust delay as needed (e.g., 2.0 to 3.0 seconds)
                                let result = collectionManager.combineCards(for: baseCard, numberOfCardsToSacrifice: maxSacrificeCount)
                                
                                isProcessingCombination = false // End suspense

                                switch result {
                                case .success(let exCardObtained):
                                    combinationPopupResultType = .success(exCardObtained)
                                    AudioManager.shared.playSound(named: "combine_success_fanfare", volume: 0.7) // More impactful sound
                                    hapticSuccess.notificationOccurred(.success)
                                case .failure:
                                    combinationPopupResultType = .failure(sacrificedCardName: baseCard.name, sacrificedCount: maxSacrificeCount)
                                    AudioManager.shared.playSound(named: "combine_fail_sound", volume: 0.7) // Distinct failure sound
                                    hapticFailure.notificationOccurred(.error)
                                case .notEnoughCards, .alreadyEX, .noEXEquivalent:
                                    combinationPopupResultType = .failure(sacrificedCardName: "Error processing combination", sacrificedCount: 0)
                                    print("Combination logic error: \(result)")
                                    AudioManager.shared.playSound(named: "error_sound", volume: 0.7)
                                    hapticFailure.notificationOccurred(.warning)
                                }
                                showCombinationResultPopup = true
                                updateCombinationState() 
                            }
                        }) {
                            VStack(spacing: 3) { // VStack for two lines of text
                                Text("Combine x\(maxSacrificeCount)")
                                    .fontWeight(.semibold)
                                Text("\(Int(min(Double(maxSacrificeCount) * 0.1, 1.0) * 100))% EX Chance")
                                    .font(.caption) // Smaller font for the chance
                                    .opacity(0.9)
                            }
                            .font(.system(size: 16)) // Base font size for "Combine x"
                            .foregroundColor(Color.purple) // Text color for combine button, can be adjusted
                            .padding(.vertical, 10) // Adjusted padding for two lines
                            .padding(.horizontal, 20)
                            .frame(minWidth: 180) // Ensure a decent width
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15).fill(Color.white) // White background like sell button
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                                    
                                    // Rainbow Glow Effect - applied to the border
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(
                                            AngularGradient(
                                                gradient: Gradient(colors: [
                                                    .red, .orange, .yellow, .green, .blue, .purple, .red
                                                ]),
                                                center: .center,
                                                angle: .degrees(rainbowGlowAngle)
                                            ),
                                            lineWidth: 2.5 // Glow line width
                                        )
                                        .blur(radius: 2.0) // Blur for glow effect
                                        .opacity(0.8) // Opacity of the glow

                                    // Regular border (can be subtle or match sell button's color if glow is too much)
                                    RoundedRectangle(cornerRadius: 15).stroke(
                                        Color.gray.opacity(0.3), // A subtle inner border if needed
                                        lineWidth: 1
                                    )
                                }
                            )
                        }
                        .disabled(isProcessingCombination)
                        .onAppear { // Start glow animation
                            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                                rainbowGlowAngle = 360
                            }
                        }
                    }
                }
                Spacer() // Pushes content up
            }
            .padding(.horizontal, 20) // Padding for the VStack content
            .padding(.bottom, 20) // Bottom padding

            // Show Suspense View
            if isProcessingCombination {
                CombinationSuspenseView()
            }

            // Show Combination Result Popup (only if not processing and result is available)
            if !isProcessingCombination && showCombinationResultPopup, let resultType = combinationPopupResultType {
                CombinationResultPopupView(resultType: resultType) {
                    showCombinationResultPopup = false
                    combinationPopupResultType = nil
                    if case .success = resultType {
                        if let sCard = selectedCard, collectionManager.cards.first(where: { $0.card == sCard && $0.count > 0 }) == nil {
                             selectedCard = nil // Close zoom if base card is gone
                        } else {
                            updateCombinationState() // Refresh in case still combinable
                        }
                    } else {
                         updateCombinationState()
                    }
                }
            }
        }
        .transition(.opacity)
        .onAppear {
            updateCombinationState()
            hapticSuccess.prepare()
            hapticFailure.prepare()
        }
        .onDisappear {
            isSelling = false
            isProcessingCombination = false // Ensure state is reset
        }
    }
}
