import SwiftUI
import AVFoundation

struct ShopView: View {
    @ObservedObject var collectionManager: CollectionManager
    @ObservedObject var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @State private var showingInsufficientCoinsAlert = false
    @State private var showingPurchaseAlert = false
    @State private var glowRotationAngle: Double = 0
    
    private let soundEffect: SystemSoundID = {
        guard let soundURL = Bundle.main.url(forResource: "purchase_sound", withExtension: "mp3") else {
            return 0
        }
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(soundURL as CFURL, &soundID)
        return soundID
    }()
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.white, Color(.systemGray5)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("\(collectionManager.coins)")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gray)
                        Text("🪙")
                            .font(.system(size: 20))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                }
                .padding()

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white)
                        .frame(width: 280, height: 300)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
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
                .padding(.bottom, 30)
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
        .alert("Insufficient Coins", isPresented: $showingInsufficientCoinsAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You need 100 coins to purchase this booster. Sell some cards to earn more coins!")
        }
        .alert("Confirm Purchase", isPresented: $showingPurchaseAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Buy") {
                HapticManager.shared.impact(style: .heavy)
                collectionManager.coins -= 100
                storeManager.boosters += 1
                AudioServicesPlaySystemSound(soundEffect)
                dismiss()
            }
        } message: {
            Text("Would you like to purchase this booster for 100 coins?")
        }
        .onChange(of: showingInsufficientCoinsAlert) { _, newValue in
            if newValue {
                HapticManager.shared.impact(style: .rigid)
            }
        }
    }
}

#Preview {
    ShopView(collectionManager: CollectionManager(), storeManager: StoreManager.shared)
}
