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

    struct MilestoneToDisplay: Identifiable {
        var id: MilestoneIdentifier
        var title: String
        var rewardDescription: String
        var iconName: String
        var rewardCard: BoosterCard? = nil
        var rewardBoosters: Int? = nil
    }

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
                            progress: totalProgress,
                            milestoneIdentifier: nil,
                            isClaimed: false,
                            canClaim: false,
                            claimAction: {}
                        )
                        .padding(.top, 10)
                        
                        ProgressCard(
                            title: "Holy Trinity",
                            subtitle: "Drop rate: 0.1%",
                            count: countCardsByRarity(.HolyT),
                            total: 3,
                            colors: [.yellow, .white],
                            progress: holyProgress,
                            milestoneIdentifier: nil, isClaimed: false, canClaim: false, claimAction: {}
                        )
                        
                        ProgressCard(
                            title: "Legendary",
                            subtitle: "Drop rate: 1%",
                            count: countCardsByRarity(.legendary),
                            total: 25,
                            colors: [.orange, .red],
                            progress: legendaryProgress,
                            milestoneIdentifier: nil, isClaimed: false, canClaim: false, claimAction: {}
                        )
                        
                        ProgressCard(
                            title: "Epic",
                            subtitle: "Drop rate: 8%",
                            count: countCardsByRarity(.epic),
                            total: 50,
                            colors: [.purple, .pink],
                            progress: epicProgress,
                            milestoneIdentifier: nil, isClaimed: false, canClaim: false, claimAction: {}
                        )
                        
                        ProgressCard(
                            title: "Rare",
                            subtitle: "Drop rate: 25%",
                            count: countCardsByRarity(.rare),
                            total: 75,
                            colors: [.blue, .cyan],
                            progress: rareProgress,
                            milestoneIdentifier: nil, isClaimed: false, canClaim: false, claimAction: {}
                        )
                        
                        ProgressCard(
                            title: "Common",
                            subtitle: "Drop rate: 75%",
                            count: countCardsByRarity(.common),
                            total: 100,
                            colors: [.gray, .gray.opacity(0.6)],
                            progress: commonProgress,
                            milestoneIdentifier: nil, isClaimed: false, canClaim: false, claimAction: {}
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
                            Image("home_icon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
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
        .onReceive(NotificationCenter.default.publisher(for: .milestoneClaimed)) { output in
            
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
    let progress: Double
    
    let milestoneIdentifier: MilestoneIdentifier?
    let isClaimed: Bool
    let canClaim: Bool
    let claimAction: () -> Void

    var percentage: Double {
        guard total > 0 else { return 0 }
        let currentProgress = min(Double(count), Double(total))
        return (currentProgress / Double(total)) * 100
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

                if let _ = milestoneIdentifier, canClaim {
                     Button(action: claimAction) {
                        Text("Réclamer !")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(10)
                     }
                } else if let _ = milestoneIdentifier, isClaimed {
                    Text("Réclamé ✔")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                 else {
                    Text(String(format: "%.1f%%", percentage))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                Text("\(count)/\(total)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Spacer()
            }
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(UIColor.systemGray5))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: total > 0 ? (min(progress, Double(total)) / Double(total)) * (UIScreen.main.bounds.width * 0.75) : 0, height: 6)
                    .animation(.easeInOut(duration: 1), value: progress)
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

struct MilestoneRewardPopup: View {
    let milestoneInfo: CollectionProgressView.MilestoneToDisplay
    let onClaim: () -> Void
    let onClose: () -> Void

    @State private var glowRotationAngle: Double = 0
    @State private var appears: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                ZStack {
                    Text(milestoneInfo.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(UIColor.label))
                        .padding(.vertical, 20)
                    
                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                    }
                    .padding(.trailing, 20)
                }
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemGray6).opacity(0.8))
                
                Divider()

                VStack(spacing: 20) {
                    if let card = milestoneInfo.rewardCard {
                        MilestoneRewardCardView(card: card)
                            .frame(height: 350 * 0.75)
                            .scaleEffect(0.75)
                            .padding(.top, 10)
                    } else if let boosterCount = milestoneInfo.rewardBoosters, boosterCount > 0 {
                        ZStack {
                            ForEach(0..<boosterCount.clamp(to: 0...5)) { index in
                                let normalizedIndex = index - (boosterCount.clamp(to: 1...5) - 1) / 2
                                let xOffset = CGFloat(normalizedIndex) * 30.0
                                let yOffset = abs(normalizedIndex) == 2 ? CGFloat(5.0) : (abs(normalizedIndex) == 1 ? CGFloat(2.0) : CGFloat(0.0))
                                                        
                                Image(index % 2 == 0 ? "booster_closed_1" : "booster_closed_2")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 100)
                                    .offset(x: xOffset, y: yOffset)
                                    .zIndex(Double(-abs(normalizedIndex)))
                            }
                        }
                        .frame(height: 120)
                        .padding(.top, 20)
                        
                    } else {
                        Image(milestoneInfo.iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .padding(.top, 20)
                            .shadow(color: .yellow.opacity(milestoneInfo.iconName == "coin" ? 0.6 : 0), radius: 10, y: 5)
                    }

                    Text(milestoneInfo.rewardDescription)
                        .font(.system(size: 18, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.horizontal)

                    Button(action: {
                        onClaim()
                    }) {
                        Text("Awesome!")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .orange.opacity(0.4), radius: 8, y: 4)
                    }
                    .padding(.horizontal, 25)
                    .padding(.bottom, 25)
                }
            }
            .frame(maxWidth: 340)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)

                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            AngularGradient(
                                colors: [.blue.opacity(0.7), .purple.opacity(0.7), .red.opacity(0.7), .orange.opacity(0.7), .yellow.opacity(0.7), .blue.opacity(0.7)],
                                center: .center,
                                startAngle: .degrees(glowRotationAngle),
                                endAngle: .degrees(glowRotationAngle + 360)
                            ),
                            lineWidth: 3
                        )
                        .blur(radius: 5)
                        .opacity(0.6)
                }
            )
            .cornerRadius(25)
            .scaleEffect(appears ? 1 : 0.9)
            .opacity(appears ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1), value: appears)
            .onAppear {
                AudioManager.shared.playSound(named: "popup_appear", volume: 0.5)
                
                withAnimation {
                    appears = true
                }
                withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
                    glowRotationAngle = 360
                }
            }
        }
        .zIndex(10)
    }
}

extension Int {
    func clamp(to range: ClosedRange<Int>) -> Int {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    CollectionProgressView(collectionManager: CollectionManager())
}
