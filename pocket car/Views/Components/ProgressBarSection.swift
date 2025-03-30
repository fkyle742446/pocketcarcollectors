import SwiftUI

struct ProgressBarSection: View {
    let viewSize: ViewSize
    @ObservedObject var collectionManager: CollectionManager
    @Binding var glowRotationAngle: Double
    @State private var progressValue: Double = 0
    
    var body: some View {
        NavigationLink(destination: CollectionProgressView(cards: collectionManager.cards, totalPossibleCards: 111, collectionManager: collectionManager)) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Collection progress")
                        .font(.system(size: viewSize == .compact ? 12 : 16))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(collectionManager.cards.count)/111")
                        .font(.system(size: viewSize == .compact ? 12 : 16))
                        .foregroundColor(.gray)
                }
                
                ProgressView(value: progressValue, total: 108)
                    .frame(height: 6)
                    .tint(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .background(Color.white)
                    .onAppear {
                        progressValue = 0
                        withAnimation(.easeOut(duration: 3.0)) {
                            progressValue = Double(collectionManager.cards.count)
                        }
                    }
                    .onDisappear {
                        progressValue = 0
                    }
            }
            .padding(15)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
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
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                }
            )
        }
        .simultaneousGesture(TapGesture().onEnded {
            HapticManager.shared.impact(style: .medium)
        })
        .padding(.horizontal, viewSize == .compact ? 12 : 32)
        .padding(.bottom, 20)
    }
}