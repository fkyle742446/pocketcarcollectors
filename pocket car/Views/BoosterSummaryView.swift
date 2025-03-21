import SwiftUI

struct BoosterSummaryView: View {
    let cards: [BoosterCard]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [.white, Color(.systemGray6)]),
                          startPoint: .top,
                          endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Title with gradient line
                Text("Résumé ouverture")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                // Gradient line under title
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.purple, .blue, .green],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 2)
                    .padding(.horizontal)
                
                // Cards grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 20)], spacing: 20) {
                    ForEach(cards, id: \.number) { card in
                        HolographicCard(cardImage: card.name,
                                       rarity: card.rarity,
                                       cardNumber: card.number)
                            .frame(width: 100, height: 150)
                            .shadow(radius: 5)
                    }
                }
                .padding()
                
                Spacer()
                
                // Next button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Suivant")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                        .shadow(color: .black.opacity(0.2), radius: 5)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    BoosterSummaryView(cards: [])
}
