import SwiftUI
import AVFoundation
import StoreKit

struct ShopView: View {
    @ObservedObject var collectionManager: CollectionManager
    @ObservedObject var storeManager: StoreManager
    @StateObject private var iapManager = IAPManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @State private var showingInsufficientCoinsAlert = false
    @State private var showingPurchaseAlert = false
    @State private var showingBundlePurchaseAlert = false
    @State private var showingPurchaseErrorAlert = false
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
            
            VStack(spacing: 10) {
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
                
                // Boosters section
                VStack(spacing: 10) {
                    boosterCard(
                        image: "booster_closed_1",
                        title: "Single x1 Booster",
                        price: 100,
                        count: 1,
                        type: .single
                    )
                    
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
                
                // IAP Section
                VStack(spacing: 8) {
                    ForEach(iapManager.products) { product in
                        coinPurchaseCard(for: product)
                    }
                }
                
                // Home button
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
                    .frame(height: 45)
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
                .padding(.top, 5)
                .padding(.bottom, 8)
            }
        }
        .task {
            await iapManager.loadProducts()
        }
        .alert("Erreur d'achat", isPresented: $showingPurchaseErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("L'achat n'a pas pu être effectué. Veuillez réessayer.")
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
    private func coinPurchaseCard(for product: Product) -> some View {
        Button {
            Task {
                do {
                    print("🎮 Attempting to purchase: \(product.id)")
                    if try await iapManager.purchase(product) {
                        // Haptic feedback for success
                        HapticManager.shared.impact(style: .heavy)
                        
                        // Play purchase sound
                        AudioServicesPlaySystemSound(soundEffect)
                        
                        if product.id == "com.pocketcarcollectors.100coins" {
                            collectionManager.coins += 100
                            print("💰 Added 100 coins")
                        } else {
                            collectionManager.coins += 500
                            print("💰 Added 500 coins")
                        }
                        collectionManager.saveCollection()
                    }
                } catch let error as IAPManager.PurchaseError {
                    print("❌ Purchase failed with error: \(error.localizedDescription)")
                    // Haptic feedback for error
                    HapticManager.shared.impact(style: .rigid)
                    showingPurchaseErrorAlert = true
                } catch {
                    print("❌ Unexpected error: \(error)")
                    // Haptic feedback for error
                    HapticManager.shared.impact(style: .rigid)
                    showingPurchaseErrorAlert = true
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white)
                    .frame(height: 80)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                HStack(spacing: 20) {
                    // Coin stack visualization
                    ZStack {
                        ForEach(0..<(product.id.contains("500") ? 3 : 1), id: \.self) { index in
                            Image("coin")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .offset(x: CGFloat(index * 4), y: CGFloat(-index * 4))
                        }
                    }
                    .frame(width: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.gray)
                        
                        Text(product.displayPrice)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal)
        }
        .disabled(iapManager.purchaseInProgress)
    }
    
    @ViewBuilder
    private func boosterCard(image: String, title: String, price: Int, count: Int, type: BoosterType, isBundle: Bool = false) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .frame(height: 200)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            Button(action: {
                selectedBoosterType = type
                if collectionManager.coins >= type.price {
                    showingPurchaseAlert = true
                } else {
                    showingInsufficientCoinsAlert = true
                }
            }) {
                VStack(spacing: 12) {
                    if isBundle {
                        // Bundle of 5 boosters
                        ZStack {
                            ForEach(0..<5) { index in
                                Image(index % 2 == 0 ? "booster_closed_1" : "booster_closed_2")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 130)
                                    .offset(x: CGFloat(index - 2) * 20)
                                    .zIndex(Double(-index))
                            }
                        }
                        .shadow(radius: 5)
                    } else {
                        Image(image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 130)
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
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    struct ScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
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
