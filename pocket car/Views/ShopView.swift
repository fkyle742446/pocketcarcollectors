import SwiftUI
import AVFoundation

struct ShopView: View {
    @ObservedObject var collectionManager: CollectionManager
    @ObservedObject var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @State private var showingInsufficientCoinsAlert = false
    @State private var showingPurchaseAlert = false
    @State private var showingBundlePurchaseAlert = false
    @State private var glowRotationAngle: Double = 0
    @State private var selectedBoosterType: BoosterType = .single
    
    enum BoosterType {
        case single
        case bundle
        
        var price: Int {
            switch self {
            case .single: return 100
            case .bundle: return 500
            }
        }
        
        var count: Int {
            switch self {
            case .single: return 1
            case .bundle: return 5
            }
        }
    }
    
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
            
            VStack {
                // Top coins display
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("\(collectionManager.coins)")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gray)
                        Image("coin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                }
                .padding(.top, 40)
                .padding(.horizontal)

                Spacer()

                // Centered boosters container
                VStack(spacing: 30) {
                    // Single Booster
                    boosterCard(
                        image: "booster_closed_1",
                        title: "Single x1 Booster",
                        price: 100,
                        count: 1,
                        type: .single
                    )
                    
                    // Bundle of 5 Boosters
                    boosterCard(
                        image: "booster_closed_2",
                        title: "Bundle Pack x5 Boosters",
                        price: 500,
                        count: 5,
                        type: .bundle,
                        isBundle: true
                    )
                }
                .padding(.horizontal)

                Spacer()

                // Bottom home button
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
                .padding(.bottom, 40)
            }
        }
        .alert("Insufficient Coins", isPresented: $showingInsufficientCoinsAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You need \(selectedBoosterType.price) coins to purchase this \(selectedBoosterType == .bundle ? "bundle" : "booster"). Sell some cards to earn more coins!")
        }
        .alert("Confirm Purchase", isPresented: $showingPurchaseAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Buy") {
                purchaseBooster(type: selectedBoosterType)
            }
        } message: {
            Text("Would you like to purchase \(selectedBoosterType == .bundle ? "5 boosters" : "this booster") for \(selectedBoosterType.price) coins?")
        }
        .onChange(of: showingInsufficientCoinsAlert) { _, newValue in
            if newValue {
                HapticManager.shared.impact(style: .rigid)
            }
        }
    }
    
    @ViewBuilder
    private func boosterCard(image: String, title: String, price: Int, count: Int, type: BoosterType, isBundle: Bool = false) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .frame(height: 280)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            Button(action: {
                selectedBoosterType = type
                if collectionManager.coins >= type.price {
                    showingPurchaseAlert = true
                } else {
                    showingInsufficientCoinsAlert = true
                }
            }) {
                VStack(spacing: 15) {
                    if isBundle {
                        // Bundle of 5 boosters
                        ZStack {
                            // Back to front rendering
                            ForEach(0..<5) { index in
                                Image(index % 2 == 0 ? "booster_closed_1" : "booster_closed_2")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 180)
                                    .offset(x: CGFloat(index - 2) * 20)
                                    .zIndex(Double(-index)) // Reverse z-index for proper stacking
                            }
                        }
                        .shadow(radius: 5)
                    } else {
                        Image(image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 180)
                            .shadow(radius: 5)
                    }
                    
                    HStack(spacing: 8) {
                        Text(title)
                            .foregroundColor(.gray)
                        Text("•")
                            .foregroundColor(.gray)
                        HStack(spacing: 4) {
                            Text("\(price)")
                                .fontWeight(.semibold)
                            Image("coin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
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
            }
            .disabled(collectionManager.coins < price)
        }
    }
    
    private func purchaseBooster(type: BoosterType) {
        HapticManager.shared.impact(style: .heavy)
        collectionManager.coins -= type.price
        storeManager.boosters += type.count
        AudioServicesPlaySystemSound(soundEffect)
        dismiss()
    }
}

#Preview {
    ShopView(collectionManager: CollectionManager(), storeManager: StoreManager.shared)
}
