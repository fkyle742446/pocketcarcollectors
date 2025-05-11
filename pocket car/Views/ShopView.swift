import SwiftUI
import AVFoundation
import StoreKit

struct ShopView: View {
    @ObservedObject var collectionManager: CollectionManager
    @ObservedObject var storeManager: StoreManager
    @StateObject private var referralManager = ReferralManager.shared
    @StateObject private var iapManager = IAPManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingInsufficientCoinsAlert = false
    @State private var showingPurchaseAlert = false
    @State private var showingPurchaseErrorAlert = false
    @State private var glowRotationAngle: Double = 0
    @State private var selectedBoosterType: BoosterType = .single

    enum BoosterType {
        case single
        case bundle
        
        var price: Int {
            switch self {
            case .single: return 100
            case .bundle: return 400
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
            
            if iapManager.productsLoaded {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack {
                                Spacer()
                                HStack(spacing: 10) {
                                    Text("\(collectionManager.coins)")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.gray)
                                    Image("coin")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 0)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                )
                            }
                            .padding(.horizontal)
                            
                            HStack(spacing: 15) {
                                boosterCard(image: "booster_closed_1", price: 100, count: 1, type: .single)
                                    .frame(maxWidth: .infinity)
                                
                                boosterCard(image: "booster_closed_2", price: 400, count: 5, type: .bundle, isBundle: true)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal)
                            
                            if iapManager.productsLoaded {
                                VStack(spacing: 12) {
                                    let sortedProducts = iapManager.products.sorted { product1, product2 in
                                        if product1.id == "com.pocketcarcollectors.pack100coins" { return true }
                                        if product2.id == "com.pocketcarcollectors.pack100coins" { return false }
                                        if product1.id == "com.pocketcarcollectors.pack500coins" { return true }
                                        return false
                                    }
                                    
                                    ForEach(sortedProducts, id: \.id) { product in
                                        coinPurchaseCard(for: product)
                                    }
                                }
                            } else {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .frame(height: 100)
                            }
                            
                            NavigationLink(destination: SlotMachineView(collectionManager: collectionManager)) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.white)
                                        .frame(height: 80)
                                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                    
                                    HStack(spacing: 20) {
                                        Image("slots")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40, height: 40)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Slot Machine")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.gray)
                                            
                                            Text("Try your luck!")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.gray.opacity(0.8))
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 4) {
                                            Text("20")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.primary)
                                            Image("coin")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 16, height: 16)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white)
                                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                        )
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.horizontal)
                            
                            NavigationLink(destination: ReferralView(referralManager: referralManager, storeManager: storeManager, collectionManager: collectionManager)) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.white)
                                        .frame(height: 80)
                                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                    
                                    HStack(spacing: 20) {
                                        Image(systemName: "person.2.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.orange)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Referral Program")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.gray)
                                            
                                            Text("Invite friends, earn rewards!")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.gray.opacity(0.8))
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                           .foregroundColor(.gray.opacity(0.5))
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 20)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image("home_icon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
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
                    .padding(.bottom, 20)
                    .padding(.top, 10)
                }
            } else {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading Store...")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.top)
                }
            }
        }
        .onAppear {
            if iapManager.products.isEmpty {
                Task { await iapManager.loadProducts() }
            }
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                glowRotationAngle = 360
            }
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
                        HapticManager.shared.impact(style: .heavy)
                        AudioServicesPlaySystemSound(soundEffect)
                        print("💰 Purchase successful")
                        
                        await MainActor.run {
                            if product.id == "com.pocketcarcollectors.pack100coins" {
                                collectionManager.coins += 100
                            } else if product.id == "com.pocketcarcollectors.pack500coins" {
                                collectionManager.coins += 500
                            }
                        }
                    }
                } catch {
                    print("❌ Purchase failed: \(error.localizedDescription)")
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
                .opacity(iapManager.purchaseInProgress ? 0.5 : 1)
            }
        }
        .disabled(iapManager.purchaseInProgress)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func boosterCard(image: String, price: Int, count: Int, type: BoosterType, isBundle: Bool = false) -> some View {
        Button(action: {
            selectedBoosterType = type
            if collectionManager.coins >= type.price {
                showingPurchaseAlert = true
            } else {
                showingInsufficientCoinsAlert = true
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white)
                    .frame(height: 180)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 15) {
                    ZStack {
                        if isBundle {
                            ZStack {
                                ForEach(0..<5) { index in
                                    let normalizedIndex = index - 2
                                    
                                    let xOffset = CGFloat(normalizedIndex) * 35.0
                                    
                                    let yOffset = abs(normalizedIndex) == 2 ? CGFloat(5.0) : (abs(normalizedIndex) == 1 ? CGFloat(2.0) : CGFloat(0.0))
                                                                        
                                    Image(index % 2 == 0 ? "booster_closed_1" : "booster_closed_2")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 80)
                                        .offset(x: xOffset, y: yOffset)
                                        .zIndex(Double(-abs(normalizedIndex)))
                                }
                            }
                            .frame(height: 90)
                            .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                            
                            Text("1 FREE")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    ZStack {
                                        Capsule().fill(Color.red)
                                        Capsule().stroke(Color.white, lineWidth: 1.5)
                                    }
                                )
                                .rotationEffect(.degrees(-10))
                                .offset(x: 50, y: -30)
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                        } else {
                            Image(image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 80)
                                .shadow(radius: 5)
                        }
                    }

                    VStack(spacing: 4) {
                        Text(isBundle ? "5 boosters" : "1 booster")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 6) {
                            if isBundle {
                                Text("500")
                                    .strikethrough()
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))
                            }
                            HStack(spacing: 4) {
                                Text("\(price)")
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.primary)
                                Image("coin")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                }
                .padding(.vertical, 15)
            }
        }
        .buttonStyle(ScaleButtonStyle())
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
