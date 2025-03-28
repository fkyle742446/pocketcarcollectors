import SwiftUI

struct CollectionProgressView: View {
    @ObservedObject var collectionManager: CollectionManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var glowRotationAngle: Double = 0
    
    private var viewSize: ViewSize {
        horizontalSizeClass == .compact ? .compact : .regular
    }
    
    private var horizontalPadding: CGFloat {
        viewSize == .compact ? 12 : 32
    }
    
    private func countCardsByRarity(_ rarity: CardRarity) -> Int {
        return collectionManager.cards.filter { card, _ in
            card.rarity == rarity
        }.count
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
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) { 
                        ProgressCard(
                            title: "Total Collection",
                            subtitle: nil,
                            count: collectionManager.cards.count,
                            total: 108,
                            glowRotationAngle: $glowRotationAngle,
                            colors: [.yellow, .orange]
                        )
                        
                        ProgressCard(
                            title: "Holy T Cars",
                            subtitle: "Drop rate: 0.1%",
                            count: countCardsByRarity(.HolyT),
                            total: 4,
                            glowRotationAngle: $glowRotationAngle,
                            colors: [.yellow, .white]
                        )
                        
                        ProgressCard(
                            title: "Legendary Cars",
                            subtitle: "Drop rate: 1%",
                            count: countCardsByRarity(.legendary),
                            total: 8,
                            glowRotationAngle: $glowRotationAngle,
                            colors: [.orange, .red]
                        )
                        
                        ProgressCard(
                            title: "Epic Cars",
                            subtitle: "Drop rate: 8%",
                            count: countCardsByRarity(.epic),
                            total: 20,
                            glowRotationAngle: $glowRotationAngle,
                            colors: [.purple, .pink]
                        )
                        
                        ProgressCard(
                            title: "Rare Cars",
                            subtitle: "Drop rate: 25%",
                            count: countCardsByRarity(.rare),
                            total: 32,
                            glowRotationAngle: $glowRotationAngle,
                            colors: [.blue, .cyan]
                        )
                        
                        ProgressCard(
                            title: "Common Cars",
                            subtitle: "Drop rate: 65.9%",
                            count: countCardsByRarity(.common),
                            total: 44,
                            glowRotationAngle: $glowRotationAngle,
                            colors: [.gray, .gray.opacity(0.6)]
                        )
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 12) 
                }
            }
            .onAppear {
                withAnimation(
                    .linear(duration: 10)
                    .repeatForever(autoreverses: false)
                ) {
                    glowRotationAngle = 360
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProgressCard: View {
    let title: String
    let subtitle: String?
    let count: Int
    let total: Int
    @Binding var glowRotationAngle: Double
    let colors: [Color]
    
    var percentage: Double {
        Double(count) / Double(total) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) { 
            HStack {
                VStack(alignment: .leading, spacing: 2) { 
                    Text(title)
                        .font(.system(size: 16, weight: .medium)) 
                        .foregroundColor(.gray)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .regular)) 
                            .foregroundColor(.gray.opacity(0.8))
                    }
                }
                
                Spacer()
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.system(size: 14, weight: .medium)) 
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("\(count)/\(total)")
                    .font(.system(size: 12)) 
                    .foregroundColor(.gray)
                Spacer()
            }
            
            ProgressView(value: Double(count), total: Double(total))
                .frame(height: 6) 
                .tint(
                    LinearGradient(
                        colors: colors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .background(Color.white)
        }
        .padding(12) 
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16) 
                    .glow(
                        fill: .angularGradient(
                            colors: [.blue, .purple, .red, .orange, .yellow, .blue],
                            center: .center,
                            startAngle: .degrees(glowRotationAngle),
                            endAngle: .degrees(glowRotationAngle + 360)
                        ),
                        lineWidth: 2.0,
                        blurRadius: 4.0
                    )
                    .opacity(0.4)
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            }
        )
    }
}

#Preview {
    NavigationView {
        CollectionProgressView(collectionManager: CollectionManager())
    }
}
