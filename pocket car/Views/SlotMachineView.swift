import SwiftUI
import AVFoundation

struct SlotMachineView: View {
    @ObservedObject var collectionManager: CollectionManager
    @Environment(\.dismiss) var dismiss
    
    // Ajout des propriétés pour l'audio
    @State private var audioPlayer: AVAudioPlayer?
    @State private var fadeTimer: Timer?
    @State private var currentVolume: Float = 0.0
    private let maxVolume: Float = 0.15 // Réduit le volume maximum à 15%
    
    private let symbols = ["red_light", "grey_car", "green_car", "blue_car"]
    private let rewards = [35, 80, 250, 600]
    private let spinCost = 20
    
    private let probabilities = [
        40, // red_light (plus fréquent)
        30, // grey_car
        20, // green_car
        10  // blue_car
    ]
    
    @State private var isSpinning: Bool = false
    @State private var selectedSymbols: [String] = ["red_light", "red_light", "red_light"]
    @State private var reward = 0
    @State private var slotScale: CGFloat = 1
    @State private var spinButtonScale: CGFloat = 1
    @State private var spinningTimer: Timer?
    @State private var reelStates: [ReelState] = [
        ReelState(spinning: false, currentSymbol: "red_light", opacity: 1),
        ReelState(spinning: false, currentSymbol: "red_light", opacity: 1),
        ReelState(spinning: false, currentSymbol: "red_light", opacity: 1)
    ]
    
    // Ajoutons une propriété pour stocker les symboles mélangés de chaque rouleau
    @State private var reelSymbols: [[String]] = [
        ["red_light", "grey_car", "green_car", "blue_car"].shuffled(),
        ["red_light", "grey_car", "green_car", "blue_car"].shuffled(),
        ["red_light", "grey_car", "green_car", "blue_car"].shuffled()
    ]
    
    // Ajoutons les propriétés pour contrôler le halo
    @State private var haloWidth: CGFloat = UIScreen.main.bounds.width - 0
    @State private var haloHeight: CGFloat = 420
    @State private var haloBaseOpacity: Double = 0.3
    @State private var haloBlurRadius: CGFloat = 80
    
    // Ajout de l'état pour l'animation des gains en haut
    @State private var showingWinnings: Bool = false
    @State private var winningAmount: Int = 0
    
    // Modifions les états pour gérer les deux types d'animations
    @State private var showingCoinsAnimation: Bool = false
    @State private var coinsChangeAmount: Int = 0
    @State private var isPositiveChange: Bool = false
    
    struct ReelState {
        var spinning: Bool
        var currentSymbol: String
        var offset: CGFloat = 0
        var finalOffset: CGFloat = 0
        var opacity: Double = 1
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack {
                HStack(spacing: 4) {
                    Spacer()
                    
                    ZStack {
                        HStack(spacing: 8) {
                            Text("\(collectionManager.coins)")
                                .font(.system(size: 24, weight: .bold))
                            Image("coin")
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Animation pour les changements de coins
                        if showingCoinsAnimation {
                            HStack(spacing: 4) {
                                Image("coin")
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                Text("\(isPositiveChange ? "+" : "-")\(abs(coinsChangeAmount))")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(isPositiveChange ? .green : .red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                            .offset(y: 40)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Ajout de l'animation des gains
                        if showingWinnings && winningAmount > 0 {
                            HStack(spacing: 4) {
                                Image("coin")
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                Text("+\(winningAmount)")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                            .offset(y: 40)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                
                ZStack(alignment: .topTrailing) {
                    // Image du croupier en arrière-plan
                    Image("croupier")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 160)
                        .offset(x: 15, y: -125)
                    
                    // Machine avec halo amélioré
                    ZStack {
                        // Halo lumineux
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                reward > 0 ?
                                LinearGradient(
                                    colors: [
                                        .green.opacity(haloBaseOpacity),
                                        .green.opacity(haloBaseOpacity/3),
                                        .green.opacity(haloBaseOpacity)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                reward < 0 ?
                                LinearGradient(
                                    colors: [
                                        .red.opacity(haloBaseOpacity),
                                        .red.opacity(haloBaseOpacity/3),
                                        .red.opacity(haloBaseOpacity)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [
                                        .white.opacity(haloBaseOpacity),
                                        .white.opacity(haloBaseOpacity/3),
                                        .white.opacity(haloBaseOpacity)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blur(radius: haloBlurRadius)
                            .frame(width: haloWidth, height: haloHeight)
                        
                        // Machine content
                        VStack(spacing: 35) {
                            HStack(spacing: 15) {
                                ForEach(0..<symbols.count, id: \.self) { i in
                                    VStack(spacing: 6) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 50, height: 50)
                                                .shadow(color: .black.opacity(0.1), radius: 2)
                                            
                                            Image(symbols[i])
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 30, height: 30)
                                                .offset(y: symbols[i] == "red_light" ? 2 : 0)
                                        }
                                        
                                        HStack(spacing: 2) {
                                            Text("\(rewards[i])")
                                                .font(.system(size: 14, weight: .bold))
                                            Image("coin")
                                                .resizable()
                                                .frame(width: 14, height: 14)
                                        }
                                        .foregroundColor(.primary)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 10)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(12)
                                }
                            }
                            
                            HStack(spacing: 20) {
                                ForEach(0..<3) { index in
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.white)
                                            .frame(width: 100, height: 120)
                                            .shadow(color: .black.opacity(0.1), radius: 5)
                                        
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                        
                                        GeometryReader { geometry in
                                            VStack(spacing: 0) {
                                                ForEach(0..<20) { _ in
                                                    ForEach(reelSymbols[index], id: \.self) { symbol in
                                                        Image(symbol)
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 60, height: 60)
                                                            .frame(width: geometry.size.width, height: geometry.size.height)
                                                            .offset(y: 0)
                                                    }
                                                }
                                            }
                                            .offset(y: reelStates[index].offset)
                                        }
                                    }
                                    .frame(width: 100, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                }
                            }
                            .scaleEffect(slotScale)
                            
                            Button(action: spin) {
                                HStack(spacing: 8) {
                                    Text("SPIN")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                    Text("\(spinCost)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.gray)
                                    Image("coin")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.white)
                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                                        
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.yellow.opacity(0.5), .orange.opacity(0.5)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    }
                                )
                            }
                            .disabled(isSpinning || collectionManager.coins < spinCost)
                            .scaleEffect(spinButtonScale)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 30)
                        .background(Color.white)
                        .cornerRadius(25)
                        .shadow(color:
                            reward > 0 ? .green.opacity(0.5) :
                            reward < 0 ? .red.opacity(0.5) :
                            .white.opacity(0.5),
                            radius: 20, x: 0, y: 0
                        )
                    }
                }
                .offset(y: 80) // Descend l'interface de la machine
                .animation(.easeInOut(duration: 0.3), value: reward)
                
                Spacer()
            }
            .padding(.bottom, 40)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .medium))
                }
            }
        }
        .onAppear {
            AudioManager.shared.stopBackgroundMusic() // Arrête la musique de fond
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                setupBackgroundMusic() // Démarre la musique des slots après un court délai
            }
        }
        .onDisappear {
            fadeOutAndStop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                AudioManager.shared.startBackgroundMusic() // Relance la musique de fond
            }
        }
    }
    
    private func spin() {
        guard !isSpinning && collectionManager.coins >= spinCost else { return }
        
        isSpinning = true
        collectionManager.coins -= spinCost
        AudioServicesPlaySystemSound(1520)
        HapticManager.shared.impact(style: .medium)
        reward = 0
        
        // Mélangeons à nouveau les symboles pour chaque rouleau
        reelSymbols = [
            symbols.shuffled(),
            symbols.shuffled(),
            symbols.shuffled()
        ]
        
        var winningSymbols: [String] = []
        
        // Premier rouleau
        let firstRoll = Int.random(in: 1...100)
        var sum = 0
        var firstSymbol = symbols[0]
        for (index, probability) in probabilities.enumerated() {
            sum += probability
            if firstRoll <= sum {
                firstSymbol = symbols[index]
                break
            }
        }
        winningSymbols.append(firstSymbol)
        
        // Deuxième rouleau - 65% de chance d'avoir le même symbole
        let secondRoll = Int.random(in: 1...100)
        if secondRoll <= 65 {
            winningSymbols.append(firstSymbol)
            
            // Troisième rouleau - 35% de chance d'avoir le même symbole si les deux premiers sont identiques
            let thirdRoll = Int.random(in: 1...100)
            if thirdRoll <= 35 {
                winningSymbols.append(firstSymbol)
            } else {
                let availableSymbols = symbols.filter { $0 != firstSymbol }
                let randomIndex = Int.random(in: 0..<availableSymbols.count)
                winningSymbols.append(availableSymbols[randomIndex])
            }
        } else {
            // Si le deuxième est différent, sélection complètement aléatoire pour les deux derniers
            let remainingSymbols = symbols.filter { $0 != firstSymbol }
            let randomIndex = Int.random(in: 0..<remainingSymbols.count)
            winningSymbols.append(remainingSymbols[randomIndex])
            
            let lastRoll = Int.random(in: 0..<symbols.count)
            winningSymbols.append(symbols[lastRoll])
        }
        
        for i in 0...2 {
            reelStates[i].offset = 0
            let symbolHeight: CGFloat = 120
            let numberOfSpins: CGFloat = 3
            let totalSymbols: CGFloat = CGFloat(reelSymbols[i].count)
            let symbolIndex = reelSymbols[i].firstIndex(of: winningSymbols[i])!
            let symbolIndexFloat: CGFloat = CGFloat(symbolIndex)
            let finalPosition: CGFloat = -(numberOfSpins * totalSymbols + symbolIndexFloat) * symbolHeight + (symbolHeight/2 - 60)
            
            let spinDuration = 2.0 + Double(i) * 0.5
            
            withAnimation(.linear(duration: spinDuration)) {
                reelStates[i].offset = finalPosition
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + spinDuration) {
                selectedSymbols[i] = winningSymbols[i]
                
                if i == 2 {
                    spinningTimer?.invalidate()
                    spinningTimer = nil
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        calculateReward()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            slotScale = 1
                            isSpinning = false
                        }
                    }
                }
            }
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            slotScale = 1.05
        }
        
        isPositiveChange = false
        coinsChangeAmount = spinCost
        withAnimation(.spring()) {
            showingCoinsAnimation = true
        }
        // Cache l'animation après 1.5 secondes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showingCoinsAnimation = false
            }
        }
        
        spinningTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            AudioServicesPlaySystemSound(1104)
            HapticManager.shared.impact(style: .rigid)
        }
    }
    
    private func calculateReward() {
        // Vérifions que les symboles sont alignés verticalement
        let symbols = selectedSymbols.map { $0 }
        
        // Pour qu'il y ait gain, il faut avoir exactement les mêmes symboles
        let uniqueSymbols = Set(symbols)
        if uniqueSymbols.count == 1 {
            // Un seul symbole unique = gain
            if let winningSymbol = symbols.first {
                switch winningSymbol {
                case "red_light": reward = 35
                case "grey_car": reward = 80
                case "green_car": reward = 250
                case "blue_car": reward = 600
                default: reward = 0
                }
                
                if reward > 0 {
                    collectionManager.coins += reward
                    AudioServicesPlaySystemSound(1326)
                    HapticManager.shared.impact(style: .heavy)
                    isPositiveChange = true
                    coinsChangeAmount = reward
                    withAnimation(.spring()) {
                        showingCoinsAnimation = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showingCoinsAnimation = false
                        }
                    }
                    // Ajout de l'animation des gains
                    winningAmount = reward
                    withAnimation(.spring()) {
                        showingWinnings = true
                    }
                    // Cache l'animation après 2 secondes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showingWinnings = false
                        }
                    }
                }
            }
        } else {
            reward = -1
            HapticManager.shared.impact(style: .rigid)
            showingCoinsAnimation = false
            showingWinnings = false
        }
    }
    
    // Ajout des fonctions pour gérer l'audio
    private func setupBackgroundMusic() {
        guard let url = Bundle.main.url(forResource: "slot_music", withExtension: "mp3") else {
            print("Could not find slot_music.mp3")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 0.0 // Start at 0
            audioPlayer?.play()
            
            // Fondu d'entrée plus doux
            fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                if let player = audioPlayer {
                    if player.volume < self.maxVolume {
                        player.volume = min(player.volume + 0.01, self.maxVolume) // Plus progressif
                    } else {
                        timer.invalidate()
                    }
                }
            }
        } catch {
            print("Erreur lors du chargement de la musique: \(error)")
        }
    }
    
    private func fadeOutAndStop() {
        fadeTimer?.invalidate()
        
        // Fondu de sortie plus doux
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if let player = self.audioPlayer {
                if player.volume > 0 {
                    player.volume = max(player.volume - 0.01, 0) // Plus progressif
                } else {
                    player.stop()
                    timer.invalidate()
                }
            }
        }
    }
}

struct SlotMachinePreview: View {
    var body: some View {
        NavigationView {
            SlotMachineView(collectionManager: CollectionManager())
        }
    }
}

struct SlotMachinePreview_Previews: PreviewProvider {
    static var previews: some View {
        SlotMachinePreview()
    }
}
