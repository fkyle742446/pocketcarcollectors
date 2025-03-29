import SwiftUI

struct ShopView: View {
    @ObservedObject var collectionManager: CollectionManager
    @ObservedObject var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @State private var showingInsufficientCoinsAlert = false
    @State private var showingPurchaseAlert = false
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.1, green: 0.15, blue: 0.2),
                            Color(red: 0.05, green: 0.05, blue: 0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                ForEach(0...Int(geometry.size.height/40), id: \.self) { row in
                    ForEach(0...Int(geometry.size.width/40), id: \.self) { col in
                        let x = CGFloat(col) * 40
                        let y = CGFloat(row) * 40
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.03))
                            .frame(width: 15, height: 3)
                            .position(x: x, y: y)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.03))
                            .frame(width: 15, height: 3)
                            .position(x: x, y: y + 5)
                    }
                }
            }
            .rotationEffect(.degrees(45))
            
            VStack(spacing: 20) {
                HStack {
                    Text("Shop")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("\(collectionManager.coins)")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        Text("🪙")
                            .font(.system(size: 20))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.2))
                    )
                }
                .padding()

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.7),
                                    Color.purple.opacity(0.7),
                                    Color.blue.opacity(0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 290, height: 310)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(Animation.linear(duration: 3).repeatForever(autoreverses: false), value: isAnimating)
                    
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 280, height: 300)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 15) {
                        Image("booster_closed_1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .shadow(radius: 5)
                        
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
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.2), radius: 4)
                    )
                }
                .padding(.bottom, 0)
            }
        }
        .onAppear {
            isAnimating = true
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
