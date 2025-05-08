
import SwiftUI

struct MilestoneRewardCardView: View {
    let card: BoosterCard
    @State private var scale: CGFloat = 0.8 // Start smaller for popup
    @State private var opacity: CGFloat = 0

    var body: some View {
        VStack {
            HolographicCard(
                cardImage: card.name, // Assuming card.name can be used to find the image
                rarity: card.rarity,
                cardNumber: card.number
            )
            .scaleEffect(scale) // Apply scaling
            .opacity(opacity)
            .onAppear {
                // Animate the card appearance
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                    scale = 1.0 // Animate to full size
                    opacity = 1.0
                }
            }
            
            // Optionally, add card name or rarity below if needed,
            // but HolographicCard already displays this info.
            // Text(card.name)
            //     .font(.headline)
            //     .padding(.top, 8)
            // Text(card.rarity.rawValue.capitalized)
            //     .font(.subheadline)
            //     .foregroundColor(.gray)
        }
    }
}

struct MilestoneRewardCardView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample card for previewing
        let sampleCard = BoosterCard(name: "Ferrari FXX-K", rarity: .legendary, number: 233)
        MilestoneRewardCardView(card: sampleCard)
            .padding()
            .background(Color.gray.opacity(0.2))
    }
}
