import SwiftUI

struct MilestoneInfo {
    let percentage: Double
    let icon: String // "coin", "questionmark.circle", etc.
    let reward: Int
    let isReached: Bool
    let isCollected: Bool
}

struct CollectionProgressView: View {
    let cards: [(card: BoosterCard, count: Int)]
    let totalPossibleCards: Int
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var collectionManager: CollectionManager
    
    private var collectionPercentage: Double {
        Double(cards.count) / Double(totalPossibleCards)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Overall Progress
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Overall Progress")
                                .font(.headline)
                            Spacer()
                            Text("\(cards.count)/\(totalPossibleCards)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // Simple Progress Bar with Milestones
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 20)
                                    .cornerRadius(10)
                                
                                // Progress
                                Rectangle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .frame(width: geometry.size.width * CGFloat(collectionPercentage))
                                    .frame(height: 20)
                                    .cornerRadius(10)
                                
                                // Milestone markers
                                ForEach([0.25, 0.5, 0.75], id: \.self) { milestone in
                                    let reachedMilestone = collectionPercentage >= milestone
                                    let xPosition = geometry.size.width * CGFloat(milestone)
                                    
                                    Circle()
                                        .fill(reachedMilestone ? Color.yellow : Color.white)
                                        .frame(width: 24, height: 24)
                                        .position(x: xPosition, y: 10)
                                        .overlay(
                                            Text("\(Int(milestone * 100))%")
                                                .font(.system(size: 10))
                                                .foregroundColor(reachedMilestone ? .black : .gray)
                                        )
                                }
                            }
                        }
                        .frame(height: 20)
                        .padding(.vertical, 10)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 5)
                    )
                    
                    // Progress by Rarity
                    ForEach(CardRarity.allCases.sorted(by: { $0.sortOrder > $1.sortOrder }), id: \.self) { rarity in
                        let count = cards.filter { $0.card.rarity == rarity }.count
                        ProgressSection(
                            title: "\(rarity.rawValue) Cards",
                            current: count,
                            total: 10,
                            color: rarity.color
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Collection Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProgressSection: View {
    let title: String
    let current: Int
    let total: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(current)/\(total)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                        .cornerRadius(10)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(Double(current) / Double(total)))
                        .frame(height: 20)
                        .cornerRadius(10)
                }
            }
            .frame(height: 20)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }
}

#Preview {
    CollectionProgressView(cards: [], totalPossibleCards: 100, collectionManager: CollectionManager())
}
