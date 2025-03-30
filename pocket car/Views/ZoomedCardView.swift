import SwiftUI
import AVFoundation

struct ZoomedCardView: View {
    @Binding var selectedCard: BoosterCard?
    @ObservedObject var collectionManager: CollectionManager
    @State private var sellSoundPlayer: AVAudioPlayer?

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
        }
    }
    
    private func playSellSound() {
        print("Attempting to play sell sound")
        guard let path = Bundle.main.path(forResource: "sell", ofType: "mp3") else {
            print("Could not find sell.mp3")
            return
        }
        let url = URL(fileURLWithPath: path)
        do {
            sellSoundPlayer = try AVAudioPlayer(contentsOf: url)
            sellSoundPlayer?.volume = 0.5
            sellSoundPlayer?.prepareToPlay()
            sellSoundPlayer?.play()
            print("Sound should be playing")
        } catch {
            print("Error playing sell sound: \(error.localizedDescription)")
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
                        playSellSound()
                        if collectionManager.sellCard(card) {
                            selectedCard = nil
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("Sell for")
                                .foregroundColor(.gray)
                            Text("\(collectionManager.coinValue(for: card.rarity))")
                                .foregroundColor(.gray)
                                .fontWeight(.bold)
                            Image("coin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 15)
                        .background(
                            Capsule()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                        )
                    }
                }
            }
        }
        .transition(.opacity)
    }
}