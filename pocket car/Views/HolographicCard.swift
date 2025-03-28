import SwiftUI

struct HolographicCard: View {
    let cardImage: String
    let rarity: CardRarity
    let cardNumber: Int
    
    init(cardImage: String, rarity: CardRarity, cardNumber: Int = 0) {
        self.cardImage = cardImage
        self.rarity = rarity
        self.cardNumber = cardNumber
    }
    
    @State var translation: CGSize = .zero
    @GestureState private var press = false
    
    private func cardThemeColor(for rarity: CardRarity) -> Color {
        switch rarity {
        case .common:
            return Color(red: 0.75, green: 0.75, blue: 0.75) // Silver
        case .rare:
            return Color(red: 0.0, green: 0.48, blue: 0.97) // Blue
        case .epic:
            return Color(red: 0.5, green: 0.0, blue: 0.5) // Purple
        case .legendary:
            return Color(red: 1, green: 0.84, blue: 0) // Gold
            
        case .HolyT:
            return Color(red: 0.1, green: 0.1, blue: 0.1) // Noir carbone profond
        }
    }

    var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                translation = value.translation
            }
            .onEnded { _ in
                withAnimation {
                    translation = .zero
                }
            }
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let imageSize = width * 0.88 // 220/250 ratio from original
            
            ZStack {
                // Card background with rarity color and texture
                RoundedRectangle(cornerRadius: width * 0.06) // 15/250 ratio
                    .fill(cardThemeColor(for: rarity))
                    .overlay(
                        Group {
                            if rarity == .HolyT {
                                CarbonPatternView()
                                    .clipShape(RoundedRectangle(cornerRadius: width * 0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: width * 0.06)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color(white: 0.9),
                                                        Color(white: 0.6),
                                                        Color(white: 0.9)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: width * 0.06)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                    .blur(radius: 1)
                            }
                        }
                    )
                
                // Car image
                Image(cardImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: width * 0.016))
                
                // Enhanced holographic effect
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.4),
                        .white.opacity(0.2),
                        .clear
                    ],
                    startPoint: UnitPoint(
                        x: 0.2 + translation.width / 500,
                        y: 0.2 + translation.height / 500
                    ),
                    endPoint: UnitPoint(
                        x: 0.8 + translation.width / 250,
                        y: 0.8 + translation.height / 250
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: width * 0.06))
                .blendMode(.overlay)
            }
            .rotation3DEffect(
                .degrees(Double(translation.height / 10)),
                axis: (x: -1, y: translation.width / 100, z: 0)
            )
            .gesture(drag)
        }
    }
}

struct CarbonPatternView: View {
    var body: some View {
        ZStack {
            // Premier motif de base
            Path { path in
                let size: CGFloat = 12
                for x in stride(from: 0, to: 500, by: size) {
                    for y in stride(from: 0, to: 500, by: size) {
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x + size, y: y + size))
                        path.move(to: CGPoint(x: x + size, y: y))
                        path.addLine(to: CGPoint(x: x, y: y + size))
                    }
                }
            }
            .stroke(Color.white.opacity(0.15), lineWidth: 1)
        }
    }
}
