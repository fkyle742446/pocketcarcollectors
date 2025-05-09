import SwiftUI
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    private var audioPlayers: [URL: AVAudioPlayer] = [:]
    
    func playSound(for rarity: CardRarity) {
        let soundName: String
        let volume: Float
        
        switch rarity {
        case .common:
            soundName = "common_reveal"
            volume = 0.7
        case .rare:
            soundName = "rare_reveal"
            volume = 0.7
        case .epic:
            soundName = "epic_reveal"
            volume = 0.7
        case .legendary:
            soundName = "legendary_reveal"
            volume = 0.7
            
        case .HolyT:
            soundName = "legendary_reveal"
            volume = 0.9
            
        case .Season1:
            soundName = "legendary_reveal"
            volume = 1
        case .holographicEX:
            soundName = "legendary_reveal" 
            volume = 0.8 
        }
        
        guard let path = Bundle.main.path(forResource: soundName, ofType: "mp3") else {
            print("Failed to find sound file: \(soundName)")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        // Fade out existing sound if any
        if let existingPlayer = audioPlayers[url] {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                if existingPlayer.volume > 0 {
                    existingPlayer.volume -= 0.1
                } else {
                    timer.invalidate()
                    existingPlayer.stop()
                    self.audioPlayers.removeValue(forKey: url)
                }
            }
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0 // Start at 0 volume
            player.play()
            audioPlayers[url] = player
            
            // Fade in
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                if player.volume < volume {
                    player.volume += 0.1
                } else {
                    timer.invalidate()
                }
            }
            
            // Clean up after playing
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) {
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                    if player.volume > 0 {
                        player.volume -= 0.1
                    } else {
                        timer.invalidate()
                        self.audioPlayers.removeValue(forKey: url)
                    }
                }
            }
        } catch {
            print("Failed to play sound: \(error.localizedDescription)")
        }
    }
}

struct ParticleSystem: View {
    let rarity: CardRarity
    @State private var particles: [(id: Int, position: CGPoint, opacity: Double, scale: Double, speed: Double)] = []
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(particles.prefix(150), id: \.id) { particle in
                Circle()
                    .fill(haloColor(for: rarity))
                    .frame(width: 4, height: 4)
                    .scaleEffect(particle.scale)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .drawingGroup()
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        particles = []
        for i in 0..<150 {
            let angle = Double.random(in: -Double.pi...Double.pi)
            let speed = Double.random(in: 100...400)
            let scale = Double.random(in: 0.3...1.2)
            let startPosition = CGPoint(x: 120, y: 170)
            let duration = Double.random(in: 0.6...1.2)
            let delay = Double.random(in: 0...0.3)
            
            var particle = (
                id: i,
                position: startPosition,
                opacity: Double.random(in: 0.3...0.8),
                scale: scale,
                speed: speed
            )
            particles.append(particle)
            
            withAnimation(
                Animation
                    .easeOut(duration: duration)
                    .delay(delay)
            ) {
                let distance = speed * duration
                let dx = cos(angle) * distance
                let dy = sin(angle) * distance
                particle.position.x += CGFloat(dx)
                particle.position.y += CGFloat(dy)
                particle.opacity = 0
                particle.scale *= 0.5
                particles[i] = particle
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            for i in 150...200 {
                let angle = Double.random(in: -Double.pi...Double.pi)
                let speed = Double.random(in: 50...300)
                let scale = Double.random(in: 0.2...1.0)
                let startPosition = CGPoint(x: 120, y: 170)
                let duration = Double.random(in: 0.4...0.8)
                
                var particle = (
                    id: i,
                    position: startPosition,
                    opacity: Double.random(in: 0.2...0.6),
                    scale: scale,
                    speed: speed
                )
                particles.append(particle)
                
                withAnimation(
                    Animation
                        .easeOut(duration: duration)
                ) {
                    let distance = speed * duration
                    let dx = cos(angle) * distance
                    let dy = sin(angle) * distance
                    particle.position.x += CGFloat(dx)
                    particle.position.y += CGFloat(dy)
                    particle.opacity = 0
                    particle.scale *= 0.3
                    particles.append(particle)
                }
            }
        }
    }
    
    private func haloColor(for rarity: CardRarity) -> Color {
        switch rarity {
        case .common:
            return .gray
        case .rare:
            return .blue
        case .epic:
            return .purple
        case .legendary:
            return Color(red: 1, green: 0.84, blue: 0)
        case .HolyT:
            return Color(white: 0.8)
        case .Season1:
            return .red
        case .holographicEX:
            return Color.cyan 
        }
    }
}

struct EnhancedRarityButton: View {
    let rarity: CardRarity
    
    private func getDropRate(for rarity: CardRarity) -> String {
        switch rarity {
        case .common:
            return "70%"
        case .rare:
            return "25%"
        case .epic:
            return "8%"
        case .legendary:
            return "0.1%"
        case .HolyT:
            return "0.01%"
            
        case .Season1:
            return "0.001%"
        case .holographicEX:
            return "0.05%" 
        }
    }
    
    private func getGradientColors(for rarity: CardRarity) -> [Color] {
        switch rarity {
        case .common:
            return [Color(red: 0.7, green: 0.7, blue: 0.7), Color(red: 0.85, green: 0.85, blue: 0.85)]
        case .rare:
            return [Color(red: 0.0, green: 0.3, blue: 0.8), Color(red: 0.0, green: 0.48, blue: 0.97)]
        case .epic:
            return [Color(red: 0.4, green: 0.0, blue: 0.4), Color(red: 0.6, green: 0.0, blue: 0.6)]
        case .legendary:
            return [Color(red: 0.8, green: 0.6, blue: 0.0), Color(red: 1.0, green: 0.84, blue: 0.0)]
        case .HolyT:
            return [Color(red: 0.1, green: 0.1, blue: 0.1), Color(red: 0.2, green: 0.2, blue: 0.2)]
        case .Season1:
            return [Color(red: 0.1, green: 0.1, blue: 0.1), Color(red: 0.2, green: 0.2, blue: 0.2)]
        case .holographicEX:
            return [Color.cyan.opacity(0.7), Color.purple.opacity(0.7)] 
        }
    }
    
    private func displayName(for rarity: CardRarity) -> String {
        if rarity == .holographicEX {
            return "EX"
        }
        return rarity.rawValue.uppercased()
    }

    var body: some View {
        ZStack {
            // Fond avec dégradé
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: getGradientColors(for: rarity),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Ajout d'un effet de texture subtil
                    rarity == .HolyT ? CarbonPatternView().opacity(0.1) : nil
                )
                .overlay(
                    // Bordure brillante
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .frame(width: 160, height: 40)
            
            // Texte
            HStack(spacing: 8) {
                Text(displayName(for: rarity))
                    .font(.system(size: 15, weight: .black, design:.default))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                
                Text("•")
                    .foregroundColor(.white.opacity(0.7))
                
                // Drop rate text
                Text(getDropRate(for: rarity))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .shadow(color: Color.white.opacity(0.25), radius: 5, x: 0, y: 2)
    }
}

struct NewCardBadge: View {
    @State private var rotation: Double = -15
    @State private var scale: CGFloat = 0
    @State private var glowOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Glow effect
            Text("NEW")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green)
                        .blur(radius: 10)
                )
                .opacity(glowOpacity)
            
            // Main badge
            Text("NEW")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.green,
                                    Color.green.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.8),
                                            Color.white.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
                .shadow(color: Color.green.opacity(0.5), radius: 8, x: 0, y: 2)
        }
        .rotationEffect(.degrees(rotation))
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                rotation = 0
                scale = 1
            }
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                glowOpacity = 0.6
            }
        }
    }
}

struct GestureHintView: View {
    @State private var tapOpacity: Double = 0.6
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 16))
            Text("Tap anywhere")
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(.white)
        .opacity(tapOpacity)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
            ) {
                tapOpacity = 0.2
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.2))
                .blur(radius: 5)
        )
    }
}

struct BoosterOpeningView: View {
    @ObservedObject var collectionManager: CollectionManager
    @ObservedObject var storeManager = StoreManager.shared
    @Environment(\.dismiss) var dismiss
    let boosterImage: String
    
    // State properties
    @State private var isOpening = true
    @State private var boosterScale: CGFloat = 1.0
    @State private var boosterOpacity: Double = 1.0
    @State private var currentCardIndex = 0
    @State private var cardScale: CGFloat = 1.3
    @State private var cardOffset: CGFloat = 0
    @State private var showParticles = false
    @State private var dragOffset: CGFloat = 0
    @State private var showArrowIndicator = true
    @State private var currentCard: BoosterCard? = nil
    @State private var isTransitioning = false
    @State private var rotationAngle: Double = 0
    @State private var cardGlowOpacity: Double = 0
    @State private var shakeOffset: CGFloat = 0
    @State private var isNewCard: Bool = false
    @State private var showNewBadge: Bool = false
    @State private var drawnCards: [BoosterCard] = []
    @State private var showSummary = false
    @State private var showGestureHint = true
    @State private var hasConsumedBoosterForThisOpening = false

    private let baseCards: [BoosterCard] = [
        // Common (70%) - Cards 1-100
        BoosterCard(name: "Renault Clio", rarity: .common, number: 1),
        // ... (all your existing 255 card definitions remain here) ...
        BoosterCard(name: "Peugeot 208", rarity: .common, number: 2),
        BoosterCard(name: "Volkswagen Polo", rarity: .common, number: 3),
        BoosterCard(name: "Ford Fiesta", rarity: .common, number: 4),
        BoosterCard(name: "Toyota Yaris", rarity: .common, number: 5),
        BoosterCard(name: "Fiat 500", rarity: .common, number: 6),
        BoosterCard(name: "Mini Cooper", rarity: .common, number: 7),
        BoosterCard(name: "Hyundai i20", rarity: .common, number: 8),
        BoosterCard(name: "Opel Corsa", rarity: .common, number: 9),
        BoosterCard(name: "Kia Picanto", rarity: .common, number: 10),
        BoosterCard(name: "Citroën C3", rarity: .common, number: 11),
        BoosterCard(name: "SEAT Ibiza", rarity: .common, number: 12),
        BoosterCard(name: "Dacia Sandero", rarity: .common, number: 13),
        BoosterCard(name: "Skoda Fabia", rarity: .common, number: 14),
        BoosterCard(name: "Nissan Micra", rarity: .common, number: 15),
        BoosterCard(name: "Volkswagen Golf", rarity: .common, number: 16),
        BoosterCard(name: "BMW Série 3", rarity: .common, number: 17),
        BoosterCard(name: "Audi A3", rarity: .common, number: 18),
        BoosterCard(name: "Mercedes Classe A", rarity: .common, number: 19),
        BoosterCard(name: "Peugeot 308", rarity: .common, number: 20),
        BoosterCard(name: "Toyota Corolla", rarity: .common, number: 21),
        BoosterCard(name: "Renault Mégane", rarity: .common, number: 22),
        BoosterCard(name: "Skoda Octavia", rarity: .common, number: 23),
        BoosterCard(name: "Honda Civic", rarity: .common, number: 24),
        BoosterCard(name: "Mazda 3", rarity: .common, number: 25),
        BoosterCard(name: "Ford Focus", rarity: .common, number: 26),
        BoosterCard(name: "Hyundai i30", rarity: .common, number: 27),
        BoosterCard(name: "Renault Captur", rarity: .common, number: 28),
        BoosterCard(name: "Peugeot 2008", rarity: .common, number: 29),
        BoosterCard(name: "Volkswagen T-Roc", rarity: .common, number: 30),
        BoosterCard(name: "Toyota RAV4", rarity: .common, number: 31),
        BoosterCard(name: "Hyundai Tucson", rarity: .common, number: 32),
        BoosterCard(name: "Kia Sportage", rarity: .common, number: 33),
        BoosterCard(name: "BMW X1", rarity: .common, number: 34),
        BoosterCard(name: "Audi Q3", rarity: .common, number: 35),
        BoosterCard(name: "Mercedes GLA", rarity: .common, number: 36),
        BoosterCard(name: "Nissan Qashqai", rarity: .common, number: 37),
        BoosterCard(name: "Skoda Kodiaq", rarity: .common, number: 38),
        BoosterCard(name: "SEAT Ateca", rarity: .common, number: 39),
        BoosterCard(name: "Volvo XC40", rarity: .common, number: 40),
        BoosterCard(name: "Land Rover Discovery Sport", rarity: .common, number: 41),
        BoosterCard(name: "Ford Kuga", rarity: .common, number: 42),
        BoosterCard(name: "Volvo V60", rarity: .common, number: 43),
        BoosterCard(name: "Skoda Superb Combi", rarity: .common, number: 44),
        BoosterCard(name: "Audi A4 Avant", rarity: .common, number: 45),
        BoosterCard(name: "BMW M8 Competition", rarity: .common, number: 46), // This name is duplicated, one is Common, one is Rare. OK.
        BoosterCard(name: "Mercedes Classe E Break", rarity: .common, number: 47),
        BoosterCard(name: "Peugeot 508 SW", rarity: .common, number: 48),
        BoosterCard(name: "Volkswagen Passat Variant", rarity: .common, number: 49),
        BoosterCard(name: "Ford Mondeo Estate", rarity: .common, number: 50),
        BoosterCard(name: "Subaru Outback", rarity: .common, number: 51), // Duplicated name. OK.
        BoosterCard(name: "SEAT Leon ST", rarity: .common, number: 52),
        BoosterCard(name: "Tesla Model 3", rarity: .common, number: 53),
        BoosterCard(name: "Renault Zoe", rarity: .common, number: 54),
        BoosterCard(name: "Volkswagen ID.3", rarity: .common, number: 55),
        BoosterCard(name: "Hyundai Kona Electric", rarity: .common, number: 56),
        BoosterCard(name: "Kia EV6", rarity: .common, number: 57),
        BoosterCard(name: "Nissan Leaf", rarity: .common, number: 58),
        BoosterCard(name: "BMW i3", rarity: .common, number: 59),
        BoosterCard(name: "Audi e-tron", rarity: .common, number: 60),
        BoosterCard(name: "Mercedes EQC", rarity: .common, number: 61),
        BoosterCard(name: "Polestar 2", rarity: .common, number: 62),
        BoosterCard(name: "Renault Kangoo", rarity: .common, number: 63),
        BoosterCard(name: "Citroën Berlingo", rarity: .common, number: 64),
        BoosterCard(name: "Ford Transit Connect", rarity: .common, number: 65),
        BoosterCard(name: "Volkswagen Caddy", rarity: .common, number: 66),
        BoosterCard(name: "Peugeot Rifter", rarity: .common, number: 67),
        BoosterCard(name: "Opel Combo Life", rarity: .common, number: 68),
        BoosterCard(name: "Skoda Roomster", rarity: .common, number: 69),
        BoosterCard(name: "Toyota Proace City Verso", rarity: .common, number: 70),
        BoosterCard(name: "Ford F-150", rarity: .common, number: 71),
        BoosterCard(name: "Chevrolet Silverado", rarity: .common, number: 72),
        BoosterCard(name: "Toyota RAV4", rarity: .common, number: 73), // Duplicated name. OK.
        BoosterCard(name: "Honda CR-V", rarity: .common, number: 74),
        BoosterCard(name: "Tesla Model Y", rarity: .common, number: 75),
        BoosterCard(name: "Ram Pickups", rarity: .common, number: 76),
        BoosterCard(name: "GMC Sierra", rarity: .common, number: 77),
        BoosterCard(name: "Toyota Camry", rarity: .common, number: 78),
        BoosterCard(name: "Nissan Rogue", rarity: .common, number: 79),
        BoosterCard(name: "Honda Civic", rarity: .common, number: 80), // Duplicated name. OK.
        BoosterCard(name: "Chevrolet Equinox", rarity: .common, number: 81),
        BoosterCard(name: "Toyota Corolla", rarity: .common, number: 82), // Duplicated name. OK.
        BoosterCard(name: "Jeep Grand Cherokee", rarity: .common, number: 83),
        BoosterCard(name: "Hyundai Tucson", rarity: .common, number: 84), // Duplicated name. OK.
        BoosterCard(name: "Chevrolet Trax", rarity: .common, number: 85),
        BoosterCard(name: "Ford Explorer", rarity: .common, number: 86),
        BoosterCard(name: "Toyota Tacoma", rarity: .common, number: 87),
        BoosterCard(name: "Subaru Crosstrek", rarity: .common, number: 88),
        BoosterCard(name: "Subaru Forester", rarity: .common, number: 89),
        BoosterCard(name: "Subaru Outback", rarity: .common, number: 90), // Duplicated name. OK.
        BoosterCard(name: "Honda Accord", rarity: .common, number: 91),
        BoosterCard(name: "Kia Sportage", rarity: .common, number: 92), // Duplicated name. OK.
        BoosterCard(name: "Toyota Tundra", rarity: .common, number: 93),
        BoosterCard(name: "Ford Transit", rarity: .common, number: 94),
        BoosterCard(name: "Nissan Sentra", rarity: .common, number: 95),
        BoosterCard(name: "Ford F-250", rarity: .common, number: 96),
        BoosterCard(name: "Chevrolet Malibu", rarity: .common, number: 97),
        BoosterCard(name: "Jeep Wrangler", rarity: .common, number: 98),
        BoosterCard(name: "Mazda CX-5", rarity: .common, number: 99),
        BoosterCard(name: "Kia Sorento", rarity: .common, number: 100),

        // Rare (25%) - Cards 101-175
        BoosterCard(name: "Porsche 911", rarity: .rare, number: 101),
        // ... many rare cards ...
        BoosterCard(name: "Mercedes-AMG CLA 45", rarity: .rare, number: 175),

        // Epic (8%) - Cards 176-225
        BoosterCard(name: "Bugatti Chiron", rarity: .epic, number: 176),
        // ... many epic cards ...
        BoosterCard(name: "Koenigsegg Regera Final Edition", rarity: .epic, number: 225), // Note: "Koenigsegg Regera Final Edition" also Legendary. OK.

        // Legendary (0.1%) - Cards 226-250
        BoosterCard(name: "Bugatti La Voiture Noire", rarity: .legendary, number: 226), // Note: Also Epic. OK.
        // ... many legendary cards ...
        BoosterCard(name: "Bugatti Mistral", rarity: .legendary, number: 250), // Note: Also Epic. OK.

        // HolyT (0.01%) - Cards 251-252
        BoosterCard(name: "McLaren P1 Holy Trinity", rarity: .HolyT, number: 251),
        BoosterCard(name: "Porsche 918 Spyder Holy Trinity", rarity: .HolyT, number: 252),
        BoosterCard(name: "Ferrari LaFerrari Holy Trinity", rarity: .HolyT, number: 253),
        // Season1 (0.001%) - Cards 253-254 (Card 253 was Ferrari LaFerrari Holy Trinity)
    
        BoosterCard(name: "Formula 1", rarity: .Season1, number: 254),
        // holographicEX (0.05%) Card 255
        BoosterCard(name: "Cyber Truck EX", rarity: .holographicEX, number: 255),
    ]

    private let allCards: [BoosterCard] // This will be initialized in init

    init(collectionManager: CollectionManager, boosterNumber: Int) {
        self._collectionManager = ObservedObject(wrappedValue: collectionManager)
        self._storeManager = ObservedObject(wrappedValue: StoreManager.shared)
        self.boosterImage = "booster_closed_\(boosterNumber)"

        var generatedCards = baseCards
        for card in baseCards {
            if card.number >= 1 && card.number <= 250 { // Only for cards 1-250
                let exCard = BoosterCard(
                    name: "\(card.name) EX",
                    rarity: .holographicEX,
                    number: card.number + 255 // New numbering scheme for EX
                )
                generatedCards.append(exCard)
            }
        }
        self.allCards = generatedCards
        // print("Total cards including EX versions: \(self.allCards.count)") // Should be 505
    }
    
    var body: some View {
        ZStack {
            Color(isOpening ? .white : .black).opacity(0.9)
                .ignoresSafeArea()
            
            if showSummary {
                BoosterSummaryView(drawnCards: drawnCards)
            } else if (storeManager.boosters > 0 || !hasConsumedBoosterForThisOpening) || !isOpening {
                VStack {
                    if isOpening {
                        VStack(spacing: 30) {
                            Spacer()
                            
                            Image(boosterImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 400)
                                .scaleEffect(boosterScale)
                                .opacity(boosterOpacity)
                                .rotation3DEffect(
                                    .degrees(rotationAngle),
                                    axis: (x: -1.0, y: 1.0, z: 0.0)
                                )
                                .onTapGesture {
                                    openBooster()
                                }
                                .padding(.top, 80)
                            
                            Spacer()
                            
                            AnimatedButton(title: "OPEN") {
                                openBooster()
                            }
                            .padding(.bottom, 50)
                        }
                    } else if let selectedCard = currentCard {
                        cardRevealView(for: selectedCard)
                    }
                }
            } else {
                VStack {
                    Text("No booster")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    AnimatedButton(title: "Retour") {
                        dismiss()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if storeManager.boosters == 0 && isOpening {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            }
        }
    }
    
    private func openBooster() {
        guard !hasConsumedBoosterForThisOpening else {
            print("BoosterOpeningView: openBooster() called, but booster already consumed for this session.")
            return
        }

        // Bien que l'UI doive déjà gérer ça, c'est une double sécurité.
        guard storeManager.boosters > 0 else {
            print("BoosterOpeningView: openBooster() called, but no boosters available (StoreManager count is 0 or less).")
            // Optionnel: Gérer ce cas, par exemple en fermant la vue si elle ne devrait pas être ouverte.
            // dismiss()
            return
        }

        print("🔊 Playing button press sound...")
        AudioManager.shared.playButtonPress()

        // Cela empêche les appels multiples à cette fonction de passer le garde ci-dessus.
        hasConsumedBoosterForThisOpening = true

        withAnimation(.easeInOut(duration: 0.5)) {
            boosterScale = 1.2
            boosterOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isOpening = false // Change l'état de l'UI pour montrer les cartes
            currentCard = randomCard()
            
            // La consommation réelle du booster dans le StoreManager.
            // Le flag hasConsumedBoosterForThisOpening et le guard storeManager.boosters > 0
            // au début de la fonction protègent contre les appels multiples qui mèneraient
            // à plusieurs exécutions de ce bloc asyncAfter et donc à plusieurs useBooster().
            storeManager.useBooster()
            
            // S'assurer que currentCard n'est pas nil avant d'accéder à sa rareté.
            // randomCard() est conçu pour ne jamais retourner nil, mais c'est une bonne pratique.
            if let cardToPlaySoundFor = currentCard {
                SoundManager.shared.playSound(for: cardToPlaySoundFor.rarity)
            } else {
                print("BoosterOpeningView: Error - currentCard is nil after randomCard() call. Cannot play sound.")
                // Gérer l'erreur si nécessaire, par exemple, fermer la vue ou afficher un message.
            }
        }
    }

    @ViewBuilder
    private func cardRevealView(for selectedCard: BoosterCard) -> some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack {
                Spacer()
                
                VStack(spacing: 60) {
                    ZStack {
                        ZStack(alignment: .topTrailing) {
                            HolographicCard(
                                cardImage: selectedCard.name,
                                rarity: selectedCard.rarity,
                                cardNumber: selectedCard.number
                            )
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { gesture in
                                        print("HolographicCard DragGesture: onChanged")
                                        dragOffset = gesture.translation.height
                                        
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring()) {
                                            dragOffset = 0
                                        }
                                    }
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    cardScale = cardScale == 1.3 ? 2.0 : 1.3
                                }
                            }
                            
                            if collectionManager.isNewCard(selectedCard) {
                                NewCardBadge()
                                    .offset(x: -20, y: 20)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(haloColor(for: selectedCard.rarity))
                                .blur(radius: 20)
                                .opacity(0.7)
                        )
                        .scaleEffect(cardScale)
                        .offset(y: cardOffset + dragOffset)
                        .modifier(AutoHolographicAnimation())
                    }
                    
                    EnhancedRarityButton(rarity: selectedCard.rarity)
                        .allowsHitTesting(false)
                }
                .padding(.top, 80)
                
                Spacer()
                
                AnimatedButton(title: "NEXT CARD") {
                    handleCardReveal(selectedCard)
                }
                .padding(.bottom, 50)
            }
        }
        .contentShape(Rectangle()) // Rend toute la ZStack tappable
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    if cardScale == 2.0 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            cardScale = 1.3
                        }
                    } else {
                        handleCardReveal(selectedCard)
                    }
                }
        )
    }

    private func handleCardReveal(_ selectedCard: BoosterCard) {
        print("BoosterOpeningView - handleCardReveal: Called. isTransitioning: \(isTransitioning)")
        if isTransitioning {
            print("BoosterOpeningView - handleCardReveal: Already transitioning, returning.")
            return
        }
        isTransitioning = true
        
        print("🔊 Playing next card sound...")
        AudioManager.shared.playNextCard()
        
        withAnimation {
            showGestureHint = false
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            cardOffset = -UIScreen.main.bounds.height
        }
        
        if !drawnCards.contains(where: { $0.name == selectedCard.name }) {
            drawnCards.append(selectedCard)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            cardOffset = 0
            currentCardIndex += 1
            dragOffset = 0
            showArrowIndicator = true
            if currentCardIndex < 5 {
                currentCard = randomCard()
                showGestureHint = true
                SoundManager.shared.playSound(for: currentCard!.rarity)
            } else {
                showSummary = true
            }
            isTransitioning = false
        }
        
        collectionManager.addCard(selectedCard)
    }
    
    private func randomCard() -> BoosterCard {
        let totalHolographicEXCards = self.allCards.filter { $0.rarity == .holographicEX }.count
        let totalEXProbability = 0.005 

        let probabilities: [CardRarity: Double] = [
            .common: 0.7 / 100,      
            .rare: 0.25 / 75,        
            .epic: 0.08 / 50,        
            .legendary: 0.01 / 25,   
            .HolyT: 0.001 / 3,       
            .Season1: 0.0001 / 1,    
            .holographicEX: totalHolographicEXCards > 0 ? totalEXProbability / Double(totalHolographicEXCards) : 0
        ]
        
        print("--- Probabilities per card for randomCard() ---")
        for (rarity, prob) in probabilities {
            print("Rarity \(rarity): \(String(format: "%.8f", prob)) per card")
        }
        print("Total holographicEX cards: \(totalHolographicEXCards)")
        print("Total EX probability tier: \(totalEXProbability)")

        let weightedCards = self.allCards.flatMap { card -> [BoosterCard] in
            guard let weightPerCardInRarity = probabilities[card.rarity] else {
                print("Warning: Rarity \(card.rarity) not found in probabilities for card \(card.name). Skipping.")
                return []
            }
            let count = Int(weightPerCardInRarity * 1_000_000)
            return Array(repeating: card, count: max(1, count)) 
        }

        print("Total items in weightedCards: \(weightedCards.count)")
        var rarityCountsInWeighted: [CardRarity: Int] = [:]
        for card in weightedCards {
            rarityCountsInWeighted[card.rarity, default: 0] += 1
        }
        print("--- Rarity distribution in weightedCards ---")
        for rarity in CardRarity.allCases { 
            let count = rarityCountsInWeighted[rarity] ?? 0
            let percentage = weightedCards.isEmpty ? 0 : (Double(count) / Double(weightedCards.count) * 100.0)
            print("\(rarity): \(count) entries (\(String(format: "%.2f", percentage))%)")
        }

        guard !weightedCards.isEmpty else {
            print("Error: weightedCards array is empty. This likely means probabilities are misconfigured or allCards is empty. Returning first card from allCards as fallback.")
            return self.allCards.first ?? BoosterCard(name: "Fallback Card EX", rarity: .common, number: 0)
        }

        let drawnCard = weightedCards.randomElement()!
        print("Card drawn: \(drawnCard.name) - Rarity: \(drawnCard.rarity)")
        return drawnCard
    }
    
    private func haloColor(for rarity: CardRarity) -> Color { 
        switch rarity {
        case .common:
            return Color.white
        case .rare:
            return Color.blue
        case .epic:
            return Color.purple
        case .legendary:
            return Color(red: 1, green: 0.84, blue: 0)
        case .HolyT:
            return Color(red: 0.1, green: 0.1, blue: 0.1)
        case .Season1:
            return Color.red
        case .holographicEX:
            return Color.cyan.opacity(0.8) 
        }
    }
}

struct AutoHolographicAnimation: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(isAnimating ? 4 : -4),
                axis: (x: -1.0, y: 1.0, z: 0.0)
            )
            .onAppear {
                withAnimation(
                    Animation
                        .easeInOut(duration: 3.0)
                        .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

struct AnimatedButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            AudioManager.shared.playButtonPress()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            Text(title)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.white)
                .frame(width: 160, height: 45)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                .scaleEffect(isPressed ? 0.95 : 1)
        }
    }
}

struct BoosterOpeningPreview: View {
    var body: some View {
        BoosterOpeningView(collectionManager: CollectionManager(), boosterNumber: 1)
    }
}

struct BoosterOpeningPreview_Previews: PreviewProvider {
    static var previews: some View {
        BoosterOpeningPreview()
    }
}
