import SwiftUI

struct BoosterSummaryView: View {
    let cards: [BoosterCard]
    let onNextTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Opening Summary")
                .font(.title)
                .foregroundColor(.gray)
                .padding(.top, 30)
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    ForEach(cards, id: \.number) { card in
                        VStack {
                            HolographicCard(
                                cardImage: card.name,
                                rarity: card.rarity,
                                cardNumber: card.number
                            )
                            .frame(height: 200)
                            
                            Text(card.name)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                }
                .padding()
            }
            
            Button(action: onNextTapped) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
            }
        }
        .background(Color.white)
    }
}
