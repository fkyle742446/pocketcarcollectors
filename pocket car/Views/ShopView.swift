import SwiftUI

struct ShopView: View {
    @ObservedObject var collectionManager: CollectionManager
    @ObservedObject var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
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
                        .foregroundColor(.gray)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("\(collectionManager.coins)")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gray)
                        Text("🪙")
                            .font(.system(size: 20))
                    }
                }
                .padding()
                
                Spacer()
                
                // Single Booster Card with reduced size
                ZStack {
                    // Card Background
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white)
                        .frame(width: 280, height: 300) // Reduced size
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 15) { // Reduced spacing
                        // Booster Image
                        Image("booster_closed_1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200) // Reduced height
                            .shadow(radius: 5)
                        
                        // Buy Button
                        Button(action: {
                            if collectionManager.coins >= 100 {
                                showingPurchaseAlert = true
                            } else {
                                showingInsufficientCoinsAlert = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text("Buy")
                                    .foregroundColor(.gray)
                                Text("•")
                                    .foregroundColor(.gray)
                                HStack(spacing: 4) {
                                    Text("100")
                                        .fontWeight(.semibold)
                                    Text("🪙")
                                }
                            }
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            )
                        }
                        .disabled(collectionManager.coins < 100)
                        .opacity(collectionManager.coins >= 100 ? 1 : 0.5)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Home Button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                }
                .padding(.bottom, 30)
            }
        }
        .alert("Insufficient Coins", isPresented: $showingInsufficientCoinsAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You need 100 coins to purchase this booster. Sell some cards to earn more coins!")
        }
        .alert("Confirm Purchase", isPresented: $showingPurchaseAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Buy") {
                collectionManager.coins -= 100
                storeManager.boosters += 1
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Would you like to purchase this booster for 100 coins?")
        }
    }
}

#Preview {
    ShopView(collectionManager: CollectionManager(), storeManager: StoreManager.shared)
}
