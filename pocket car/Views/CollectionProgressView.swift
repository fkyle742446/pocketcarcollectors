import SwiftUI

struct CollectionProgressView: View {
    let cards: [(card: BoosterCard, count: Int)]
    let totalPossibleCards: Int
    @Environment(\.dismiss) private var dismiss
    
    // Move rarity calculations to a computed property
    private var rarityProgress: [(rarity: CardRarity, current: Int, total: Int)] {
        CardRarity.allCases
            .sorted(by: { $0.sortOrder > $1.sortOrder })
            .map { rarity in
                let count = cards.filter { $0.card.rarity == rarity }.count
                return (rarity: rarity, current: count, total: 10)
            }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Overall Progress
                    ProgressSection(
                        title: "Overall Progress",
                        current: cards.count,
                        total: totalPossibleCards,
                        color: .blue
                    )
                    
                    // Progress by Rarity
                    ForEach(rarityProgress, id: \.rarity) { progress in
                        ProgressSection(
                            title: "\(progress.rarity.rawValue) Cards",
                            current: progress.current,
                            total: progress.total,
                            color: progress.rarity.color
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
    var color: Color = .blue
    
    private var percentage: Double {
        Double(current) / Double(total)
    }
    
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
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percentage), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }
}
