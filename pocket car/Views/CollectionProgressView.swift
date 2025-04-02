import SwiftUI

struct CollectionProgressView: View {
    @ObservedObject var collectionManager: CollectionManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dismiss) var dismiss
    @State private var glowRotationAngle: Double = 0
    
    @State private var totalProgress: Double = 0
    @State private var holyProgress: Double = 0
    @State private var legendaryProgress: Double = 0
    @State private var epicProgress: Double = 0
    @State private var rareProgress: Double = 0
    @State private var commonProgress: Double = 0
    
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
                            total: 250,
                            colors: [.yellow, .orange],
                            progress: totalProgress
                        )
                        .padding(.top, 10)
                        
                        ProgressCard(
                            title: "Holy Trinity",
                            subtitle: "Drop rate: 0.1%",
                            count: countCardsByRarity(.HolyT),
                            total: 3,
                            colors: [.yellow, .white],
                            progress: holyProgress
                        )
                        
                        ProgressCard(
                            title: "Legendary",
                            subtitle: "Drop rate: 1%",
                            count: countCardsByRarity(.legendary),
                            total: 25,
                            colors: [.orange, .red],
                            progress: legendaryProgress
                        )
                        
                        ProgressCard(
                            title: "Epic",
                            subtitle: "Drop rate: 8%",
                            count: countCardsByRarity(.epic),
                            total: 50,
                            colors: [.purple, .pink],
                            progress: epicProgress
                        )
                        
                        ProgressCard(
                            title: "Rare",
                            subtitle: "Drop rate: 25%",
                            count: countCardsByRarity(.rare),
                            total: 75,
                            colors: [.blue, .cyan],
                            progress: rareProgress
                        )
                        
                        ProgressCard(
                            title: "Common",
                            subtitle: "Drop rate: 75%",
                            count: countCardsByRarity(.common),
                            total: 100,
                            colors: [.gray, .gray.opacity(0.6)],
                            progress: commonProgress
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
            totalProgress = 0
            holyProgress = 0
            legendaryProgress = 0
            epicProgress = 0
            rareProgress = 0
            commonProgress = 0
            
            withAnimation(.easeOut(duration: 2.0)) {
                totalProgress = Double(collectionManager.cards.count)
                holyProgress = Double(countCardsByRarity(.HolyT))
                legendaryProgress = Double(countCardsByRarity(.legendary))
                epicProgress = Double(countCardsByRarity(.epic))
                rareProgress = Double(countCardsByRarity(.rare))
                commonProgress = Double(countCardsByRarity(.common))
            }
            
            withAnimation(
                .linear(duration: 10)
                .repeatForever(autoreverses: false)
            ) {
                glowRotationAngle = 360
            }
        }
        .onDisappear {
            totalProgress = 0
            holyProgress = 0
            legendaryProgress = 0
            epicProgress = 0
            rareProgress = 0
            commonProgress = 0
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

struct CollectionProgressStats {
    let collected: Int
    let total: Int = 250
    let common: Int
    let rare: Int
    let epic: Int
    let legendary: Int
    let holyT: Int
    
    var commonTotal: Int { 100 }    // 100 cartes communes
    var rareTotal: Int { 75 }       // 75 cartes rares
    var epicTotal: Int { 50 }       // 50 cartes épiques
    var legendaryTotal: Int { 25 }  // 25 cartes légendaires
    
    var progressPercentage: Double {
        return Double(collected) / Double(total) * 100
    }
}

struct ProgressCard: View {
    let title: String
    let subtitle: String?
    let count: Int
    let total: Int
    let colors: [Color]
    let progress: Double
    
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
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white)
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: progress / Double(total) * UIScreen.main.bounds.width * 0.75, height: 6)
                    .animation(.easeInOut(duration: 3.0), value: progress)
            }
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
