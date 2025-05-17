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
        case .referral:
            soundName = "referral_reveal"
            volume = 0.75
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
        case .referral:
            return Color(red: 0.2, green: 0.7, blue: 0.3)
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
            return "1%"
        case .referral:
            return "Special"
        case .HolyT:
            return "0.1%"
            
        case .Season1:
            return "0.01%"
        case .holographicEX:
            return "0.1%"
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
        case .referral:
            return [Color(red: 0.1, green: 0.6, blue: 0.2), Color(red: 0.3, green: 0.8, blue: 0.4)]
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
        if rarity == .referral {
            return "ELECTRIC"
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

enum BoosterContext {
    case generic(boosterNumber: Int)
    case referral
    
    var imageName: String {
        switch self {
        case .generic(let number):
            return "booster_closed_\(number)"
        case .referral:
            return "referral_booster_icon"
        }
    }

    var isReferral: Bool {
        if case .referral = self { return true }
        return false
    }
}

struct BoosterOpeningView: View {
    @ObservedObject var collectionManager: CollectionManager
    @ObservedObject var storeManager = StoreManager.shared
    @Environment(\.dismiss) var dismiss
    let context: BoosterContext
    
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
        BoosterCard(name: "Renault Clio", rarity: .common, number: 1),
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
        BoosterCard(name: "BMW M8 Competition", rarity: .common, number: 46),
        BoosterCard(name: "Mercedes Classe E Break", rarity: .common, number: 47),
        BoosterCard(name: "Peugeot 508 SW", rarity: .common, number: 48),
        BoosterCard(name: "Volkswagen Passat Variant", rarity: .common, number: 49),
        BoosterCard(name: "Ford Mondeo Estate", rarity: .common, number: 50),
        BoosterCard(name: "Subaru Outback", rarity: .common, number: 51),
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
        BoosterCard(name: "Toyota RAV4", rarity: .common, number: 73),
        BoosterCard(name: "Honda CR-V", rarity: .common, number: 74),
        BoosterCard(name: "Tesla Model Y", rarity: .common, number: 75),
        BoosterCard(name: "Ram Pickups", rarity: .common, number: 76),
        BoosterCard(name: "GMC Sierra", rarity: .common, number: 77),
        BoosterCard(name: "Toyota Camry", rarity: .common, number: 78),
        BoosterCard(name: "Nissan Rogue", rarity: .common, number: 79),
        BoosterCard(name: "Honda Civic", rarity: .common, number: 80),
        BoosterCard(name: "Chevrolet Equinox", rarity: .common, number: 81),
        BoosterCard(name: "Toyota Corolla", rarity: .common, number: 82),
        BoosterCard(name: "Jeep Grand Cherokee", rarity: .common, number: 83),
        BoosterCard(name: "Hyundai Tucson", rarity: .common, number: 84),
        BoosterCard(name: "Chevrolet Trax", rarity: .common, number: 85),
        BoosterCard(name: "Ford Explorer", rarity: .common, number: 86),
        BoosterCard(name: "Toyota Tacoma", rarity: .common, number: 87),
        BoosterCard(name: "Subaru Crosstrek", rarity: .common, number: 88),
        BoosterCard(name: "Subaru Forester", rarity: .common, number: 89),
        BoosterCard(name: "Subaru Outback", rarity: .common, number: 90),
        BoosterCard(name: "Honda Accord", rarity: .common, number: 91),
        BoosterCard(name: "Kia Sportage", rarity: .common, number: 92),
        BoosterCard(name: "Toyota Tundra", rarity: .common, number: 93),
        BoosterCard(name: "Ford Transit", rarity: .common, number: 94),
        BoosterCard(name: "Nissan Sentra", rarity: .common, number: 95),
        BoosterCard(name: "Ford F-250", rarity: .common, number: 96),
        BoosterCard(name: "Chevrolet Malibu", rarity: .common, number: 97),
        BoosterCard(name: "Jeep Wrangler", rarity: .common, number: 98),
        BoosterCard(name: "Mazda CX-5", rarity: .common, number: 99),
        BoosterCard(name: "Kia Sorento", rarity: .common, number: 100),

        BoosterCard(name: "Porsche 911", rarity: .rare, number: 101),
              BoosterCard(name: "Mercedes-AMG GT", rarity: .rare, number: 102),
              BoosterCard(name: "Audi RS6", rarity: .rare, number: 103),
              BoosterCard(name: "BMW M5", rarity: .rare, number: 104),
              BoosterCard(name: "Lexus LC", rarity: .rare, number: 105),
              BoosterCard(name: "Acura NSX", rarity: .rare, number: 106),
              BoosterCard(name: "Jaguar F-Type", rarity: .rare, number: 107),
              BoosterCard(name: "Maserati Quattroporte", rarity: .rare, number: 108),
              BoosterCard(name: "Alfa Romeo Giulia Quadrifoglio", rarity: .rare, number: 109),
              BoosterCard(name: "Cadillac CT6-V", rarity: .rare, number: 110),
              BoosterCard(name: "Dodge Challenger SRT Hellcat", rarity: .rare, number: 111),
              BoosterCard(name: "Ford Mustang Shelby GT500", rarity: .rare, number: 112),
              BoosterCard(name: "Chevrolet Corvette Z06", rarity: .rare, number: 113),
              BoosterCard(name: "Nissan 370Z", rarity: .rare, number: 114),
              BoosterCard(name: "Aston Martin DBX", rarity: .rare, number: 115),
              BoosterCard(name: "Bentley Bentayga", rarity: .rare, number: 116),
              BoosterCard(name: "Rolls-Royce Ghost", rarity: .rare, number: 117),
              BoosterCard(name: "Lamborghini Urus", rarity: .rare, number: 118),
              BoosterCard(name: "Ferrari Roma", rarity: .rare, number: 119),
              BoosterCard(name: "McLaren GT", rarity: .rare, number: 120),
              BoosterCard(name: "Porsche Panamera", rarity: .rare, number: 121),
              BoosterCard(name: "BMW 8 Series", rarity: .rare, number: 122),
              BoosterCard(name: "Mercedes-Benz S-Class Coupe", rarity: .rare, number: 123),
              BoosterCard(name: "Audi RS7", rarity: .rare, number: 124),
              BoosterCard(name: "Tesla Model S Plaid", rarity: .rare, number: 125),
              BoosterCard(name: "Polestar 1", rarity: .rare, number: 126),
              BoosterCard(name: "Rimac C_Two", rarity: .rare, number: 127),
              BoosterCard(name: "Lotus Evija", rarity: .rare, number: 128),
              BoosterCard(name: "Pininfarina Battista", rarity: .rare, number: 129),
              BoosterCard(name: "Aston Martin Valhalla", rarity: .rare, number: 130),
              BoosterCard(name: "Bugatti Divo", rarity: .rare, number: 131),
              BoosterCard(name: "Koenigsegg Gemera", rarity: .rare, number: 132),
              BoosterCard(name: "Pagani Huayra", rarity: .rare, number: 133),
              BoosterCard(name: "Ferrari SF90 Stradale", rarity: .rare, number: 134),
              BoosterCard(name: "McLaren 765LT", rarity: .rare, number: 135),
              BoosterCard(name: "Lamborghini Huracan STO", rarity: .rare, number: 136),
              BoosterCard(name: "Porsche 911 GT3", rarity: .rare, number: 137),
              BoosterCard(name: "Mercedes-AMG GT Black Series", rarity: .rare, number: 138),
              BoosterCard(name: "Audi R8 V10 Performance", rarity: .rare, number: 139),
              BoosterCard(name: "BMW M8 Competition", rarity: .rare, number: 140),
              BoosterCard(name: "Lexus LFA", rarity: .rare, number: 141),
              BoosterCard(name: "Acura NSX Type S", rarity: .rare, number: 142),
              BoosterCard(name: "Jaguar XJR-575", rarity: .rare, number: 143),
              BoosterCard(name: "Maserati MC20", rarity: .rare, number: 144),
              BoosterCard(name: "Alfa Romeo 4C Spider", rarity: .rare, number: 145),
              BoosterCard(name: "Cadillac CT5-V Blackwing", rarity: .rare, number: 146),
              BoosterCard(name: "Dodge Viper ACR", rarity: .rare, number: 147),
              BoosterCard(name: "Ford GT", rarity: .rare, number: 148),
              BoosterCard(name: "Chevrolet Camaro ZL1", rarity: .rare, number: 149),
              BoosterCard(name: "Nissan GT-R Nismo", rarity: .rare, number: 150),
              BoosterCard(name: "Aston Martin Vantage", rarity: .rare, number: 151),
              BoosterCard(name: "Bentley Continental GT Speed", rarity: .rare, number: 152),
              BoosterCard(name: "Rolls-Royce Wraith", rarity: .rare, number: 153),
              BoosterCard(name: "Lamborghini Aventador SVJ Roadster", rarity: .rare, number: 154),
              BoosterCard(name: "Ferrari 812 GTS", rarity: .rare, number: 155),
              BoosterCard(name: "Porsche 911 Turbo S", rarity: .rare, number: 156),
              BoosterCard(name: "Mercedes-AMG GT R", rarity: .rare, number: 157),
              BoosterCard(name: "Audi RS Q8", rarity: .rare, number: 158),
              BoosterCard(name: "BMW X8 M", rarity: .rare, number: 159),
              BoosterCard(name: "Lexus LC Convertible", rarity: .rare, number: 160),
              BoosterCard(name: "Jaguar F-Type R", rarity: .rare, number: 161),
              BoosterCard(name: "Maserati Levante Trofeo", rarity: .rare, number: 162),
              BoosterCard(name: "Alfa Romeo Stelvio Quadrifoglio", rarity: .rare, number: 163),
              BoosterCard(name: "Cadillac CT4-V Blackwing", rarity: .rare, number: 164),
              BoosterCard(name: "Dodge Charger SRT Hellcat Redeye", rarity: .rare, number: 165),
              BoosterCard(name: "Ford Mustang Mach 1", rarity: .rare, number: 166),
              BoosterCard(name: "Chevrolet Camaro SS", rarity: .rare, number: 167),
              BoosterCard(name: "Nissan 370Z Nismo", rarity: .rare, number: 168),
              BoosterCard(name: "Aston Martin DB11 AMR", rarity: .rare, number: 169),
              BoosterCard(name: "Bentley Flying Spur", rarity: .rare, number: 170),
              BoosterCard(name: "Rolls-Royce Ghost Extended", rarity: .rare, number: 171),
              BoosterCard(name: "Lamborghini Huracan Performante Spyder", rarity: .rare, number: 172),
              BoosterCard(name: "Ferrari Portofino M", rarity: .rare, number: 173),
              BoosterCard(name: "Porsche 718 Cayman GT4", rarity: .rare, number: 174),
              BoosterCard(name: "Mercedes-AMG CLA 45", rarity: .rare, number: 175),

        BoosterCard(name: "Bugatti Chiron", rarity: .epic, number: 176),
              BoosterCard(name: "Koenigsegg Jesko", rarity: .epic, number: 177),
              BoosterCard(name: "Pagani Huayra BC", rarity: .epic, number: 178),
              BoosterCard(name: "McLaren Senna", rarity: .epic, number: 179),
              BoosterCard(name: "Ferrari Monza SP2", rarity: .epic, number: 180),
              BoosterCard(name: "Aston Martin Vulcan", rarity: .epic, number: 181),
              BoosterCard(name: "Lamborghini Centenario", rarity: .epic, number: 182),
              BoosterCard(name: "Bugatti Divo", rarity: .epic, number: 183),
              BoosterCard(name: "Koenigsegg Regera", rarity: .epic, number: 184),
              BoosterCard(name: "Pagani Zonda Revolucion", rarity: .epic, number: 185),
              BoosterCard(name: "McLaren P1 GTR", rarity: .epic, number: 186),
              BoosterCard(name: "Ferrari FXX-K", rarity: .epic, number: 187),
              BoosterCard(name: "Aston Martin Valkyrie AMR Pro", rarity: .epic, number: 188),
              BoosterCard(name: "Lamborghini Sian Roadster", rarity: .epic, number: 189),
              BoosterCard(name: "Bugatti La Voiture Noire", rarity: .epic, number: 190),
              BoosterCard(name: "Koenigsegg Agera RSR", rarity: .epic, number: 191),
              BoosterCard(name: "Pagani Imola", rarity: .epic, number: 192),
              BoosterCard(name: "McLaren Elva", rarity: .epic, number: 193),
              BoosterCard(name: "Ferrari SF90 Spider", rarity: .epic, number: 194),
              BoosterCard(name: "Aston Martin DB10", rarity: .epic, number: 195),
              BoosterCard(name: "Lamborghini SC18 Alston", rarity: .epic, number: 196),
              BoosterCard(name: "Bugatti Bolide", rarity: .epic, number: 197),
              BoosterCard(name: "Koenigsegg One:1", rarity: .epic, number: 198),
              BoosterCard(name: "Pagani Zonda Cinque Roadster", rarity: .epic, number: 199),
              BoosterCard(name: "McLaren Speedtail", rarity: .epic, number: 200),
              BoosterCard(name: "Ferrari P80/C", rarity: .epic, number: 201),
              BoosterCard(name: "Aston Martin Victor", rarity: .epic, number: 202),
              BoosterCard(name: "Lamborghini Essenza SCV12", rarity: .epic, number: 203),
              BoosterCard(name: "Bugatti Centodieci", rarity: .epic, number: 204),
              BoosterCard(name: "Koenigsegg CCXR Edition", rarity: .epic, number: 205),
              BoosterCard(name: "Pagani Huayra Tricolore", rarity: .epic, number: 206),
              BoosterCard(name: "McLaren 600LT Spider", rarity: .epic, number: 207),
              BoosterCard(name: "Ferrari 488 Pista Spider", rarity: .epic, number: 208),
              BoosterCard(name: "Aston Martin DBS Superleggera", rarity: .epic, number: 209),
              BoosterCard(name: "Lamborghini Huracan Performante", rarity: .epic, number: 210),
              BoosterCard(name: "Bugatti Mistral", rarity: .epic, number: 211),
              BoosterCard(name: "Koenigsegg CC850", rarity: .epic, number: 212),
              BoosterCard(name: "Pagani Utopia", rarity: .epic, number: 213),
              BoosterCard(name: "McLaren Artura", rarity: .epic, number: 214),
              BoosterCard(name: "Ferrari 296 GTB", rarity: .epic, number: 215),
              BoosterCard(name: "Aston Martin Valhalla AMR", rarity: .epic, number: 216),
              BoosterCard(name: "Bugatti Chiron Pur Sport", rarity: .epic, number: 217),
              BoosterCard(name: "Koenigsegg Jesko Attack", rarity: .epic, number: 218),
              BoosterCard(name: "Pagani Huayra R", rarity: .epic, number: 219),
              BoosterCard(name: "McLaren 720S Spider", rarity: .epic, number: 220),
              BoosterCard(name: "Ferrari 812 Competizione", rarity: .epic, number: 221),
              BoosterCard(name: "Aston Martin V12 Speedster", rarity: .epic, number: 222),
              BoosterCard(name: "Lamborghini Aventador Ultimate", rarity: .epic, number: 223),
              BoosterCard(name: "Bugatti Chiron Super Sport", rarity: .epic, number: 224),
              BoosterCard(name: "Koenigsegg Regera Final Edition", rarity: .epic, number: 225),

        BoosterCard(name: "Koenigsegg Jesko Absolut", rarity: .legendary, number: 226),
               BoosterCard(name: "Pagani Zonda Cinque", rarity: .legendary, number: 227),
               BoosterCard(name: "Lamborghini Sesto Elemento", rarity: .legendary, number: 228),
               BoosterCard(name: "Bugatti Bolide", rarity: .legendary, number: 229),
               BoosterCard(name: "McLaren F1 GTR Longtail", rarity: .legendary, number: 230),
               BoosterCard(name: "Ferrari F40 LM", rarity: .legendary, number: 231),
               BoosterCard(name: "Koenigsegg One:1", rarity: .legendary, number: 232),
               BoosterCard(name: "Aston Martin Valkyrie Pro", rarity: .legendary, number: 233),
               BoosterCard(name: "Pagani Huayra BC Roadster", rarity: .legendary, number: 234),
               BoosterCard(name: "Lamborghini Centenario Roadster", rarity: .legendary, number: 235),
               BoosterCard(name: "Bugatti Divo Lady Bug", rarity: .legendary, number: 236),
               BoosterCard(name: "McLaren P1 GTR", rarity: .legendary, number: 237),
               BoosterCard(name: "Ferrari Monza SP1", rarity: .legendary, number: 238),
               BoosterCard(name: "Koenigsegg Regera Final Edition", rarity: .legendary, number: 239),
               BoosterCard(name: "Aston Martin Valkyrie Spider", rarity: .legendary, number: 240),
               BoosterCard(name: "Pagani Zonda R", rarity: .legendary, number: 241),
               BoosterCard(name: "Lamborghini SC20", rarity: .legendary, number: 242),
               BoosterCard(name: "Bugatti La Voiture Noire", rarity: .legendary, number: 243),
               BoosterCard(name: "McLaren Senna LM", rarity: .legendary, number: 244),
               BoosterCard(name: "Ferrari 250 GT California Spyder", rarity: .legendary, number: 245),
               BoosterCard(name: "Koenigsegg CCXR Special Edition", rarity: .legendary, number: 246),
               BoosterCard(name: "Aston Martin DB5", rarity: .legendary, number: 247),
               BoosterCard(name: "Pagani Zonda F", rarity: .legendary, number: 248),
               BoosterCard(name: "Lamborghini Miura SV", rarity: .legendary, number: 249),
               BoosterCard(name: "Bugatti Chiron Super Sport 300+", rarity: .legendary, number: 250),

        BoosterCard(name: "McLaren P1 Holy Trinity", rarity: .HolyT, number: 251),
        BoosterCard(name: "Porsche 918 Spyder Holy Trinity", rarity: .HolyT, number: 252),
        BoosterCard(name: "Ferrari LaFerrari Holy Trinity", rarity: .HolyT, number: 253),
        
        BoosterCard(name: "Formula 1", rarity: .Season1, number: 254),
      
        BoosterCard(name: "Cyber Truck EX", rarity: .holographicEX, number: 255),
    ]

    private let allCards: [BoosterCard]
    private let referralCardPool: [BoosterCard] = [
        BoosterCard(name: "Tesla Model S", rarity: .referral, number: 256, imageName: "Tesl Model S"),
        BoosterCard(name: "Tesla Model 3", rarity: .referral, number: 257, imageName: "Tesla Model 3"),
        BoosterCard(name: "Tesla Model X", rarity: .referral, number: 258, imageName: "Tesla Model X"),
        BoosterCard(name: "Tesla Model Y", rarity: .referral, number: 259, imageName: "Tesla Model Y"),
        BoosterCard(name: "Porsche Taycan", rarity: .referral, number: 260, imageName: "Porsche Taycan"),
        BoosterCard(name: "Audi e-tron GT", rarity: .referral, number: 261, imageName: "Audi e tron GT"),
        BoosterCard(name: "Jaguar I-PACE", rarity: .referral, number: 262, imageName: "Jaguar I PACE"),
        BoosterCard(name: "Nissan Leaf", rarity: .referral, number: 263, imageName: "Nissan Leaf"),
        BoosterCard(name: "Chevrolet Bolt EV", rarity: .referral, number: 264, imageName: "Chevrolet Bolt EV"),
        BoosterCard(name: "Ford Mustang Mach-E", rarity: .referral, number: 265, imageName: "Ford Mustang Mach E"),
        BoosterCard(name: "BMW i3", rarity: .referral, number: 266, imageName: "BMW i3"),
        BoosterCard(name: "Hyundai Kona Electric", rarity: .referral, number: 267, imageName: "Hyundai Kona Electric"),
        BoosterCard(name: "Kia Soul EV", rarity: .referral, number: 268, imageName: "Kia Soul EV"),
        BoosterCard(name: "Rivian R1T", rarity: .referral, number: 269, imageName: "Rivian R1T"),
        BoosterCard(name: "Rivian R1S", rarity: .referral, number: 270, imageName: "Rivian R1S"),
        BoosterCard(name: "Lucid Air", rarity: .referral, number: 271, imageName: "Lucid Air"),
        BoosterCard(name: "Polestar 2", rarity: .referral, number: 272, imageName: "Polestar 2"),
        BoosterCard(name: "Ford F-150 Lightning", rarity: .referral, number: 273, imageName: "Ford F 150 Lightning"),
        BoosterCard(name: "GMC Hummer EV", rarity: .referral, number: 274, imageName: "GMC Hummer EV"),
        BoosterCard(name: "Volkswagen ID.4", rarity: .referral, number: 275, imageName: "Volkswagen ID.4"),
        BoosterCard(name: "Tesla Cybertruck", rarity: .referral, number: 276, imageName: "Tesla Cybertruck"),
        BoosterCard(name: "BMW i8", rarity: .referral, number: 277, imageName: "BMW i8"),
        BoosterCard(name: "Tesla Roadster", rarity: .referral, number: 278, imageName: "Tesla Roadster"),
        BoosterCard(name: "Audi e-tron", rarity: .referral, number: 279, imageName: "Audi e tron"),
        BoosterCard(name: "Mercedes-Benz EQC", rarity: .referral, number: 280, imageName: "Mercedes Benz EQC"),
        BoosterCard(name: "Volvo XC40 Recharge", rarity: .referral, number: 281, imageName: "Volvo XC40 Recharge"),
        BoosterCard(name: "Hyundai Ioniq 5", rarity: .referral, number: 282, imageName: "Hyundai Ioniq 5"),
        BoosterCard(name: "Kia EV6", rarity: .referral, number: 283, imageName: "Kia EV6"),
        BoosterCard(name: "Nissan Ariya", rarity: .referral, number: 284, imageName: "Nissan Ariya"),
        BoosterCard(name: "Ford E-Transit", rarity: .referral, number: 285, imageName: "Ford E Transit"),
        BoosterCard(name: "Chevrolet Silverado EV", rarity: .referral, number: 286, imageName: "Chevrolet Silverado EV"),
        BoosterCard(name: "GMC Sierra EV", rarity: .referral, number: 287, imageName: "GMC Sierra EV"),
        BoosterCard(name: "Ram 1500 EV", rarity: .referral, number: 288, imageName: "Ram 1500 EV"),
        BoosterCard(name: "Tesla Semi", rarity: .referral, number: 289, imageName: "Tesla Semi"),
        BoosterCard(name: "Rivian EDV", rarity: .referral, number: 290, imageName: "Rivian EDV"),
        BoosterCard(name: "BrightDrop EV600", rarity: .referral, number: 291, imageName: "BrightDrop EV600"),
        BoosterCard(name: "Ford E-Transit Van", rarity: .referral, number: 292, imageName: "Ford E- Transit Van"),
        BoosterCard(name: "Mercedes-Benz eSprinter", rarity: .referral, number: 293, imageName: "Mercedes Benz eSprinter"),
        BoosterCard(name: "Volkswagen ID. Buzz", rarity: .referral, number: 294, imageName: "Volkswagen ID Buzz"),
        BoosterCard(name: "Canter E-Cell", rarity: .referral, number: 295, imageName: "Canter E Cell"),
        BoosterCard(name: "BYD T3", rarity: .referral, number: 296, imageName: "BYD T3"),
        BoosterCard(name: "Nissan e-NV200", rarity: .referral, number: 297, imageName: "Nissan e NV200"),
        BoosterCard(name: "Renault Kangoo Z.E.", rarity: .referral, number: 298, imageName: "Renault Kangoo Z.E."),
        BoosterCard(name: "Peugeot e-Partner", rarity: .referral, number: 299, imageName: "Peugeot e Partner"),
        BoosterCard(name: "Citroen e-Berlingo", rarity: .referral, number: 300, imageName: "Citroen e Berlingo"),
        BoosterCard(name: "Opel Vivaro-e", rarity: .referral, number: 301, imageName: "Opel Vivaro e"),
        BoosterCard(name: "Fiat E-Ducato", rarity: .referral, number: 302, imageName: "Fiat E Ducato"),
        BoosterCard(name: "Iveco Daily Electric", rarity: .referral, number: 303, imageName: "Iveco Daily Electric"),
        BoosterCard(name: "Maxus eDeliver 3", rarity: .referral, number: 304, imageName: "Maxus eDeliver 3"),
        BoosterCard(name: "LDV EV80", rarity: .referral, number: 305, imageName: "LDV EV80")

        // Add more referral-specific cards here
    ]

    private let referralTierProbabilities: [CardRarity: Double] = [
        .referral: 1.0
    ]

    private let probabilityToDrawReferralCardInEarlySlots: Double = 0.20 // 20% chance

    init(collectionManager: CollectionManager, context: BoosterContext) {
        self._collectionManager = ObservedObject(wrappedValue: collectionManager)
        self._storeManager = ObservedObject(wrappedValue: StoreManager.shared)
        self.context = context

        var generatedCards = baseCards
        for card in baseCards {
            if card.number >= 1 && card.number <= 250 &&
               card.rarity != .holographicEX && card.rarity != .HolyT && card.rarity != .Season1 {
                // If your EX assets are named like "Card Name EX" (with a space), use this:
                let exImageName = "\(card.imageName) EX" // Adds a space before EX
                // If your EX assets are named like "CardNameEX" (no space), original was likely fine:
                // let exImageName = "\(card.imageName)EX" 

                let exCard = BoosterCard(
                    name: "\(card.name) EX",
                    rarity: .holographicEX,
                    number: card.number + 255,
                    imageName: exImageName // Use the potentially corrected imageName
                )
                generatedCards.append(exCard)
            }
        }
        self.allCards = generatedCards
        print("BoosterOpeningView: Initialized. Context: \(context). Total generic cards (incl. derived EX from numbers <=250): \(self.allCards.count)")
        if self.allCards.count != 605 && !context.isReferral {
            print("WARNING: Expected 605 generic cards, but found \(self.allCards.count). Check baseCards and EX generation logic if all cards are intended to be in this list.")
        }
        print("ELECTRIC card pool size: \(self.referralCardPool.count)")
    }

    var body: some View {
        ZStack {
            Color(isOpening ? .white : .black).opacity(0.9)
                .ignoresSafeArea()
            
            if showSummary {
                BoosterSummaryView(drawnCards: drawnCards)
            } else if (context.isReferral ? storeManager.referralBoostersToOpen > 0 : storeManager.boosters > 0) || !hasConsumedBoosterForThisOpening || !isOpening {
                VStack {
                    if isOpening {
                        VStack(spacing: 30) {
                            Spacer()
                            Image(context.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 400)
                                .scaleEffect(boosterScale)
                                .opacity(boosterOpacity)
                                .rotation3DEffect(
                                    .degrees(rotationAngle),
                                    axis: (x: -1.0, y: 1.0, z: 0.0)
                                )
                                .onTapGesture { openBooster() }
                                .padding(.top, 80)
                            Spacer()
                            AnimatedButton(title: "OPEN") { openBooster() }
                                .padding(.bottom, 50)
                        }
                    } else if let selectedCard = currentCard {
                        cardRevealView(for: selectedCard)
                    }
                }
            } else {
                VStack {
                    Text("No booster available")
                        .font(.title).foregroundColor(.white)
                    AnimatedButton(title: "Retour") { dismiss() }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            let noBoostersAvailable = context.isReferral ? (storeManager.referralBoostersToOpen == 0) : (storeManager.boosters == 0)
            if noBoostersAvailable && isOpening {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { dismiss() }
            }
        }
    }
    
    private func openBooster() {
        guard !hasConsumedBoosterForThisOpening else { return }

        let canOpen = context.isReferral ? (storeManager.referralBoostersToOpen > 0) : (storeManager.boosters > 0)
        guard canOpen else {
            print("BoosterOpeningView: openBooster() called, but no \(context.isReferral ? "ELECTRIC" : "GENERIC") boosters available.")
            return
        }

        AudioManager.shared.playButtonPress()
        hasConsumedBoosterForThisOpening = true

        withAnimation(.easeInOut(duration: 0.5)) {
            boosterScale = 1.2
            boosterOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isOpening = false
            if context.isReferral {
                currentCard = self.drawNextCardForReferralBooster()
            } else {
                currentCard = self.randomGenericCard()
            }
            
            if context.isReferral {
                storeManager.useReferralBooster()
            } else {
                storeManager.useBooster()
            }
            
            if let cardToPlaySoundFor = currentCard {
                SoundManager.shared.playSound(for: cardToPlaySoundFor.rarity)
            } else {
                print("BoosterOpeningView: Error - currentCard is nil for the first card. Cannot play sound.")
            }
        }
    }

    @ViewBuilder
    private func cardRevealView(for selectedCard: BoosterCard) -> some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            VStack {
                Spacer()
                VStack(spacing: 60) {
                    ZStack {
                        ZStack(alignment: .topTrailing) {
                            HolographicCard(
                                cardImage: selectedCard.imageName,
                                rarity: selectedCard.rarity,
                                cardNumber: selectedCard.number
                            )
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { gesture in dragOffset = gesture.translation.height }
                                .onEnded { _ in withAnimation(.spring()) { dragOffset = 0 } }
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    cardScale = cardScale == 1.3 ? 2.0 : 1.3
                                }
                            }
                            if collectionManager.isNewCard(selectedCard) {
                                NewCardBadge().offset(x: -20, y: 20)
                                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .scale.combined(with: .opacity)))
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 20).fill(haloColor(for: selectedCard.rarity)).blur(radius: 20).opacity(0.7))
                        .scaleEffect(cardScale)
                        .offset(y: cardOffset + dragOffset)
                        .modifier(AutoHolographicAnimation())
                    }
                    EnhancedRarityButton(rarity: selectedCard.rarity).allowsHitTesting(false)
                }
                .padding(.top, 80)
                Spacer()
                AnimatedButton(title: "NEXT CARD") { handleCardReveal(selectedCard) }
                    .padding(.bottom, 50)
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded { _ in
            if cardScale == 2.0 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cardScale = 1.3 }
            } else {
                handleCardReveal(selectedCard)
            }
        })
    }

    private func handleCardReveal(_ selectedCard: BoosterCard) {
        if isTransitioning { return }
        isTransitioning = true
        AudioManager.shared.playNextCard()
        withAnimation { showGestureHint = false }
        withAnimation(.easeInOut(duration: 0.3)) { cardOffset = -UIScreen.main.bounds.height }
        
        if !drawnCards.contains(where: { $0.number == selectedCard.number }) {
            drawnCards.append(selectedCard)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            cardOffset = 0
            currentCardIndex += 1 // This tracks how many cards have been revealed (0 to 4 for 5 cards)
            dragOffset = 0
            showArrowIndicator = true
            
            if currentCardIndex < 5 { // Assuming 5 cards per booster
                if context.isReferral {
                    currentCard = self.drawNextCardForReferralBooster()
                } else {
                    currentCard = self.randomGenericCard()
                }
                showGestureHint = true
                if let card = currentCard { SoundManager.shared.playSound(for: card.rarity) }
            } else {
                showSummary = true
            }
            isTransitioning = false
        }
        collectionManager.addCard(selectedCard)
    }

    private func drawNextCardForReferralBooster() -> BoosterCard {
        if currentCardIndex == 4 {
            print("Drawing GUARANTEED ELECTRIC card for slot 5 (index 4).")
            return randomReferralCard()
        } else {
            if Double.random(in: 0...1) < probabilityToDrawReferralCardInEarlySlots {
                print("Drawing ELECTRIC card for early slot \(currentCardIndex + 1) due to probability roll.")
                return randomReferralCard()
            } else {
                print("Drawing generic card for early slot \(currentCardIndex + 1) due to probability roll.")
                return randomGenericCard()
            }
        }
    }

    private func randomGenericCard() -> BoosterCard {
        let tierProbabilities: [CardRarity: Double] = [
            .common:        0.70, .rare:   0.25, .epic:    0.08, .legendary: 0.01,
            .HolyT:         0.001, .Season1: 0.0001, .holographicEX: 0.01
        ]
        var totalTierProb: Double = 0
        let sortedTierProbabilities = tierProbabilities.sorted { $0.key.sortOrder < $1.key.sortOrder }
        for (_, prob) in sortedTierProbabilities { totalTierProb += prob }
        if abs(totalTierProb - 1.0) > 0.00001 { print("WARNING: Generic tier prob sum is \(totalTierProb)")}

        let randomTarget = Double.random(in: 0.0..<totalTierProb)
        var cumulativeProbability: Double = 0.0
        var selectedRarity: CardRarity = .common

        for (rarity, probability) in sortedTierProbabilities {
            cumulativeProbability += probability
            if randomTarget < cumulativeProbability { selectedRarity = rarity; break }
        }
        
        let cardsInSelectedRarity = self.allCards.filter { $0.rarity == selectedRarity }
        guard let drawnCard = cardsInSelectedRarity.randomElement() else {
            print("Error: No generic cards for rarity \(selectedRarity). Fallback.");
            return self.allCards.randomElement() ?? BoosterCard(name: "Generic Fallback", rarity: .common, number: 0, imageName: "fallback_generic")
        }
        print("Generic Card: \(drawnCard.name) (\(drawnCard.rarity)) drawn for generic booster or ELECTRIC early slot.")
        return drawnCard
    }

    private func randomReferralCard() -> BoosterCard {
        var totalTierProb: Double = 0
        let sortedTierProbabilities = referralTierProbabilities.sorted { $0.key.sortOrder < $1.key.sortOrder }
        for (_, prob) in sortedTierProbabilities { totalTierProb += prob }
        if abs(totalTierProb - 1.0) > 0.00001 { print("WARNING: Referral tier prob sum is \(totalTierProb)")}

        let randomTarget = Double.random(in: 0.0..<totalTierProb)
        var cumulativeProbability: Double = 0.0
        var selectedRarity: CardRarity = .common

        for (rarity, probability) in sortedTierProbabilities {
            cumulativeProbability += probability
            if randomTarget < cumulativeProbability { selectedRarity = rarity; break }
        }

        let cardsInSelectedRarity = self.referralCardPool.filter { $0.rarity == selectedRarity }
        guard let drawnCard = cardsInSelectedRarity.randomElement() else {
             print("Error: No ELECTRIC cards for rarity \(selectedRarity). Fallback.");
            return self.referralCardPool.randomElement() ?? BoosterCard(name: "ELECTRIC Fallback", rarity: .common, number: 800, imageName: "fallback_referral")
        }
        print("ELECTRIC Card: \(drawnCard.name) (\(drawnCard.rarity)) drawn from ELECTRIC pool.")
        return drawnCard
    }
    
    private func countCards(for rarity: CardRarity) -> Int {
        return (context.isReferral ? referralCardPool : allCards).filter { $0.rarity == rarity }.count
    }

    private func haloColor(for rarity: CardRarity) -> Color {
        switch rarity {
        case .common: return Color.white
        case .rare: return Color.blue
        case .epic: return Color.purple
        case .legendary: return Color(red: 1, green: 0.84, blue: 0)
        case .referral: return Color(red: 0.2, green: 0.7, blue: 0.3)
        case .HolyT: return Color(red: 0.1, green: 0.1, blue: 0.1)
        case .Season1: return Color.red
        case .holographicEX: return Color.cyan.opacity(0.8)
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
        BoosterOpeningView(collectionManager: CollectionManager(), context: .referral)
    }
}

struct BoosterOpeningPreview_Previews: PreviewProvider {
    static var previews: some View {
        BoosterOpeningPreview()
    }
}
