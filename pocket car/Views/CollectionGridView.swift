import SwiftUI
import AVFoundation

struct CollectionGridView: View {
    let cards: [(card: BoosterCard, count: Int)]
    @Binding var selectedCard: BoosterCard?
    @State private var showingCollectionProgress = false
    
    private let sellSound: SystemSoundID = {
        guard let soundURL = Bundle.main.url(forResource: "sell_sound", withExtension: "mp3") else {
            return 0
        }
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(soundURL as CFURL, &soundID)
        return soundID
    }()
    
    // Total number of unique cards possible
    private let totalPossibleCards = 50 // Ajustez ce nombre selon votre collection totale
    
    var body: some View {
        VStack {
            // Collection Progress Button
            Button(action: {
                showingCollectionProgress = true
            }) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                    Text("Collection Progress")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(cards.count)/\(totalPossibleCards)")
                        .fontWeight(.bold)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 5)
                )
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Existing Grid View
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(sortedCards, id: \.card.id) { entry in
                        CardView(card: entry.card, count: entry.count)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selectedCard = entry.card
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $showingCollectionProgress) {
            CollectionProgressView(cards: cards, totalPossibleCards: totalPossibleCards)
        }
    }
    
    private var sortedCards: [(card: BoosterCard, count: Int)] {
        cards.sorted { lhs, rhs in
            lhs.card.rarity.sortOrder > rhs.card.rarity.sortOrder
        }
    }
}
