import SwiftUI

struct CollectionProgressView: View {
    @ObservedObject var collectionManager: CollectionManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dismiss) var dismiss
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
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.white, Color(.systemGray5)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ProgressCard(
                            title: "Total Collection",
                            subtitle: nil,
                            count: collectionManager.cards.count,
                            total: 111,
                            colors: [.yellow, .orange]
                        )
                        .padding(.top, 10)
                        
                        ProgressCard(
                            title: "Holy Trinity",
                            subtitle: "Drop rate: 0.1%",
                            count: countCardsByRarity(.HolyT),
                            total: 3,
                            colors: [.yellow, .white]
                        )
                        
                        ProgressCard(
                            title: "Legendary",
                            subtitle: "Drop rate: 1%",
                            count: countCardsByRarity(.legendary),
                            total: 8,
                            colors: [.orange, .red]
                        )
                        
                        ProgressCard(
                            title: "Epic",
                            subtitle: "Drop rate: 8%",
                            count: countCardsByRarity(.epic),
                            total: 10,
                            colors: [.purple, .pink]
                        )
                        
                        ProgressCard(
                            title: "Rare",
                            subtitle: "Drop rate: 25%",
                            count: countCardsByRarity(.rare),
                            total: 20,
                            colors: [.blue, .cyan]
                        )
                        
                        ProgressCard(
                            title: "Common",
                            subtitle: "Drop rate: 65.9%",
                            count: countCardsByRarity(.common),
                            total: 70,
                            colors: [.gray, .gray.opacity(0.6)]
                        )
                        
                        Spacer()
                            .frame(height: 20)
                    }
                    .padding(.horizontal, horizontalPadding)
                }
                
                VStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "house.fill")
                                .font(.system(size: 16))
                            Text("Home")
                                .font(.headline)
                        }
                        .foregroundColor(.gray)
                        .frame(width: 120)
                        .frame(height: 50)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 25)
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
                                
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.white)
                            }
                        )
                    }
                    .padding(.vertical, 20)
                }
                .background(Color.clear)
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
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

struct ProgressCard: View {
    let title: String
    let subtitle: String?
    let count: Int
    let total: Int
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
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 4)
        )
    }
}

#Preview {
    CollectionProgressView(collectionManager: CollectionManager())
}
