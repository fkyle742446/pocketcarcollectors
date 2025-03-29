import SwiftUI

struct ShopView: View {
    @ObservedObject var collectionManager: CollectionManager
    @ObservedObject var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingInsufficientCoinsAlert = false
    @State private var showingPurchaseAlert = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [.white, Color(.systemGray5)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Shop")
                        .font(.system(size: 24, weight: .bold))
                    Spacer()
                    HStack {
                        Text("\(collectionManager.coins)")
                            .font(.system(size: 20, weight: .semibold))
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.yellow)
                    }
                }
                .padding()
                
                // Booster Cards Section
                ScrollView {
                    VStack(spacing: 25) {
                        // Classic Booster
                        BoosterShopCard(
                            image: "booster_closed_1",
                            title: "Classic Booster",
                            price: 100,
                            coins: collectionManager.coins
                        ) {
                            if collectionManager.coins >= 100 {
                                showingPurchaseAlert = true
                            } else {
                                showingInsufficientCoinsAlert = true
                            }
                        }
                        
                        // Premium Booster
                        BoosterShopCard(
                            image: "booster_closed_2",
                            title: "Premium Booster",
                            price: 200,
                            coins: collectionManager.coins
                        ) {
                            if collectionManager.coins >= 200 {
                                showingPurchaseAlert = true
                            } else {
                                showingInsufficientCoinsAlert = true
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .alert("Insufficient Coins", isPresented: $showingInsufficientCoinsAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You need more coins to purchase this booster. Sell some cards to earn more coins!")
        }
        .alert("Confirm Purchase", isPresented: $showingPurchaseAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Buy") {
                collectionManager.coins -= 100
                storeManager.boosters += 1
                dismiss()
            }
        } message: {
            Text("Would you like to purchase this booster for 100 coins?")
        }
    }
}

struct BoosterShopCard: View {
    let image: String
    let title: String
    let price: Int
    let coins: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Card Background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 10)
                
                HStack(spacing: 20) {
                    // Booster Image
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100)
                        .shadow(radius: 5)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(title)
                            .font(.system(size: 20, weight: .bold))
                        
                        HStack {
                            Text("\(price)")
                                .font(.system(size: 18, weight: .semibold))
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(coins >= price ? .yellow : .gray)
                        }
                    }
                    
                    Spacer()
                    
                    // Buy Button
                    Image(systemName: "cart.fill")
                        .font(.system(size: 24))
                        .foregroundColor(coins >= price ? .blue : .gray)
                        .padding()
                        .background(
                            Circle()
                                .fill(coins >= price ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                        )
                }
                .padding()
            }
        }
        .disabled(coins < price)
    }
}

#Preview {
    ShopView(collectionManager: CollectionManager(), storeManager: StoreManager.shared)
}