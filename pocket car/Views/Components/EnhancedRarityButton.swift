import SwiftUI

struct EnhancedRarityButton: View {
    let rarity: CardRarity
    
    private func getGradientColors(for rarity: CardRarity) -> [Color] {
        switch rarity {
        case .common:
            return [Color(red: 0.7, green: 0.7, blue: 0.7), Color(red: 0.85, green: 0.85, blue: 0.85)]
        case .rare:
            return [Color(red: 0.0, green: 0.3, blue: 0.8), Color(red: 0.0, green: 0.48, blue: 0.97)]
        case .epic:
            return [Color(red: 0.4, green: 0.0, blue: 0.4), Color(red: 0.6, green: 0.0, blue: 0.6)]
        case .legendary:
            return [Color(red: 0.8, green: 0.6, blue: 0.0), Color(red: 1.0, green: 0.84, blue: 0.0)]
        case .HolyT:
            return [Color(red: 0.1, green: 0.1, blue: 0.1), Color(red: 0.2, green: 0.2, blue: 0.2)]
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: getGradientColors(for: rarity),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    rarity == .HolyT ? CarbonPatternView().opacity(0.1) : nil
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .frame(width: 160, height: 45)
            
            Text(rarity.rawValue.uppercased())
                .font(.system(size: 15, weight: .black, design:.default))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
        }
        .shadow(color: getGradientColors(for: rarity).first?.opacity(0.3) ?? .clear, radius: 5, x: 0, y: 2)
    }
}