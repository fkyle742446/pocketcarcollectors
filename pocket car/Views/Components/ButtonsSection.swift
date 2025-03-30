import SwiftUI

struct ButtonsSection: View {
    let viewSize: ViewSize
    @ObservedObject var collectionManager: CollectionManager
    @Binding var glowRotationAngle: Double
    @State private var coinScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 15) {
            // Collection Button
            NavigationLink(destination: CollectionView(collectionManager: collectionManager)) {
                buttonView(icon: "", text: "", colors: [.gray.opacity(0.3)], textColor: .gray)
                    .overlay(
                        Image("collection")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                    )
            }
            .simultaneousGesture(TapGesture().onEnded {
                HapticManager.shared.impact(style: .medium)
            })
            
            // Shop Button
            NavigationLink(destination: ShopView(collectionManager: collectionManager, storeManager: StoreManager.shared)) {
                buttonView(icon: "", text: "", colors: [.gray.opacity(0.3)], textColor: .gray)
                    .overlay(
                        HStack(spacing: 4) {
                            Text("\(collectionManager.coins)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            Image("coin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .scaleEffect(coinScale)
                                .onAppear {
                                    withAnimation(
                                        .easeInOut(duration: 1.0)
                                        .repeatForever(autoreverses: true)
                                    ) {
                                        coinScale = 1.1
                                    }
                                }
                        }
                    )
            }
            .simultaneousGesture(TapGesture().onEnded {
                HapticManager.shared.impact(style: .medium)
            })
        }
        .padding(.horizontal, viewSize == .compact ? 12 : 32)
        .padding(.vertical, viewSize == .compact ? 8 : 15)
    }
    
    private func buttonView(icon: String, text: String, colors: [Color], textColor: Color) -> some View {
        // Existing buttonView implementation...
    }
}