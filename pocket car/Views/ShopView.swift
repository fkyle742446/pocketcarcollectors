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
                        VStack(spacing: 20) {
                            Spacer(minLength: 20)
                            
                            // Top coins display
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
                            
                            Spacer(minLength: 20)
                            
                            // Boosters section
                            HStack(spacing: 15) {
                                // Single Booster
                                boosterCard(image: "booster_closed_1", price: 100, count: 1, type: .single)
                                    .frame(maxWidth: .infinity)
                                
                                // Bundle Pack
                                boosterCard(image: "booster_closed_2", price: 400, count: 5, type: .bundle, isBundle: true)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal)
                            
                            // IAP Section
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
                                .padding(.top, 8)
                            } else {
                                // Loading indicator for products
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .frame(height: 100)
                            }
                            
                            // Slot Machine Button
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
                            .padding(.top, 8)
                            
                            Spacer(minLength: 100)
                        }
                    }
                    
                    // Home button en bas fixe
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
                    .padding(.vertical, 20)
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
                Task {
                    await iapManager.loadProducts()
                }
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
                            // NOTE: You might want to add a general save function for collectionManager here if needed
                            // e.g., collectionManager.saveCollection()
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
            ZStack { // Arrière-plan de la carte
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white)
                    .frame(height: 180)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 15) { // Contenu principal de la carte
                    ZStack { // Conteneur pour les images de boosters
                        if isBundle {
                            // Affichage des 5 boosters avec décalages
                            ZStack {
                                ForEach(0..<5) { index in
                                    // Index normalisé de -2 (gauche) à +2 (droite), 0 au centre
                                    let normalizedIndex = index - 2
                                    
                                    // Décalage horizontal pour les espacer ou les faire se chevaucher
                                    // Un facteur plus petit les rapproche (chevauchement si < largeur image)
                                    // Un facteur plus grand les espace davantage
                                    let xOffset = CGFloat(normalizedIndex) * 35.0 // Ajustez 35.0 pour l'espacement désiré
                                    
                                    // Léger décalage vertical pour les boosters extérieurs pour un effet de profondeur ou d'arc très subtil
                                    // Mettre à 0 si vous voulez un alignement vertical parfait.
                                    let yOffset = abs(normalizedIndex) == 2 ? CGFloat(5.0) : (abs(normalizedIndex) == 1 ? CGFloat(2.0) : CGFloat(0.0))
                                                                        
                                    Image(index % 2 == 0 ? "booster_closed_1" : "booster_closed_2")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 80) // Hauteur de chaque image de booster
                                        .offset(x: xOffset, y: yOffset)
                                        // zIndex pour que le booster central (index 2) soit au-dessus
                                        .zIndex(Double(-abs(normalizedIndex)))
                                }
                            }
                            .frame(height: 90) // Hauteur du conteneur des boosters, ajustez si besoin
                            .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                            
                            // Badge "1 FREE"
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
                                .rotationEffect(.degrees(-10)) // Garder une petite rotation pour le style du badge
                                // Ajuster l'offset du badge
                                .offset(x: 50, y: -30) // Ajustez selon la nouvelle disposition des boosters
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                        } else {
                            // Affichage pour un booster unique
                            Image(image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 80)
                                .shadow(radius: 5)
                        }
                    } // Fin ZStack images boosters

                    // VStack pour le texte (nombre de boosters et prix)
                    VStack(spacing: 4) {
                        Text(isBundle ? "5 boosters" : "1 booster")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 6) {
                            if isBundle {
                                Text("500") // Prix barré
                                    .strikethrough()
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))
                            }
                            HStack(spacing: 4) { // Prix actuel
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
                } // Fin VStack contenu principal
                .padding(.vertical, 15)
            } // Fin ZStack arrière-plan carte
        } // Fin Button
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
