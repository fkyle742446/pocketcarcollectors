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
                            Image(systemName: "info.circle")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        .padding(.top, 20)
                        .padding(.leading, 8)
                        .sheet(isPresented: $showingRarityInfo) {
                            RarityInfoView()
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
    var body: some View {
        // Background gradient et contenu restent dans NavigationView
        NavigationView {
            ZStack {
                // Ajout d'un fond dégradé
                LinearGradient(gradient: Gradient(colors: [.black, Color.gray.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // En-tête avec titre décoratif
                    Text("Drop Rates")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 30)
                    
                    // Cartes de rareté
                    VStack(spacing: 15) {
                        rarityCard(rarity: "Common", chance: "70%", color: .white, icon: "circle.fill")
                        rarityCard(rarity: "Rare", chance: "25%", color: .blue, icon: "star.fill")
                        rarityCard(rarity: "Epic", chance: "10%", color: .purple, icon: "sparkles")
                        rarityCard(rarity: "Legendary", chance: "2%", color: .yellow, icon: "crown.fill")
                        rarityCard(rarity: "Holy Trinity", chance: "0.1%", color: .orange, icon: "bolt.fill")
                    }
                    .padding()
                    
                    // Note informative
                    Text("Open boosters to collect all cards!")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 20)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // Fonction d'aide pour créer une carte de rareté
    private func rarityCard(rarity: String, chance: String, color: Color, icon: String) -> some View {
        HStack {
            // Icône et nom de la rareté
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20))
                Text(rarity)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Spacer()
            
            // Pourcentage
            Text(chance)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

struct EmptyCollectionView: View {
    var body: some View {
        Spacer()
        Text("Vous n'avez pas encore de cartes dans votre collection.")
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
            return Color(red: 1, green: 0.84, blue: 0)
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
            return Color(red: 1, green: 0.84, blue: 0) // Golden color
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
