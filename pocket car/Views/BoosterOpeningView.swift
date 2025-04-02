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
        }
    }
}

struct EnhancedRarityButton: View {
    let rarity: CardRarity
    
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
        }
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
                .frame(width: 160, height: 45)
            
            // Texte
            Text(rarity.rawValue.uppercased())
                .font(.system(size: 15, weight: .black, design:.default))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
        }
        .shadow(color: getGradientColors(for: rarity).first?.opacity(0.3) ?? .clear, radius: 5, x: 0, y: 2)
    }
}

struct NewCardBadge: View {
    var body: some View {
        Text("NEW")
            .font(.system(size: 8, weight: .black))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .rotationEffect(.degrees(0))
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
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
    
    private let allCards: [BoosterCard] = [
        // Common (40%) - Cards 1-100
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
        BoosterCard(name: "BMW Série 5 Touring", rarity: .common, number: 46),
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

        // Rare (30%) - Cards 101-175
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

        // Epic (20%) - Cards 176-225
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
        BoosterCard(name: "Lamborghini Aventador Ultimae", rarity: .epic, number: 223),
        BoosterCard(name: "Bugatti Chiron Super Sport", rarity: .epic, number: 224),
        BoosterCard(name: "Koenigsegg Regera Final Edition", rarity: .epic, number: 225),

        // Legendary (10%) - Cards 226-250
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
        BoosterCard(name: "Bugatti Chiron Super Sport 300+", rarity: .legendary, number: 250)
,
        
        // HolyT (0,1%) - Cards 251-253
    
        BoosterCard(name: "McLaren P1 Holy Trinity", rarity: .HolyT, number: 251),
        BoosterCard(name: "Ferrari LaFerrari Holy Trinity", rarity: .HolyT, number: 252),
        BoosterCard(name: "Porsche 918 Spyder Holy Trinity", rarity: .HolyT, number: 253)
    ]
    
    init(collectionManager: CollectionManager, boosterNumber: Int) {
        self._collectionManager = ObservedObject(wrappedValue: collectionManager)
        self._storeManager = ObservedObject(wrappedValue: StoreManager.shared)
        self.boosterImage = "booster_closed_\(boosterNumber)"
    }
    
    var body: some View {
        ZStack {
            // CHANGE: Conditional background color based on isOpening
            Color(isOpening ? .white : .black).opacity(0.9)
                .ignoresSafeArea()
            
            if showSummary {
                BoosterSummaryView(drawnCards: drawnCards)
            } else if storeManager.boosters > 0 || !isOpening {
                VStack {
                    if isOpening {
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
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    boosterScale = 1.2
                                    boosterOpacity = 0
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isOpening = false
                                    currentCard = randomCard()
                                    storeManager.useBooster()
                                }
                            }
                    } else if let selectedCard = currentCard {
                        cardRevealView(for: selectedCard)
                    }
                }
            } else {
                VStack {
                    Text("Pas de booster disponible")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Button("Retour") {
                        dismiss()
                    }
                    .padding()
                    .foregroundColor(.white)
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
    
    @ViewBuilder
    private func cardRevealView(for selectedCard: BoosterCard) -> some View {
        VStack(spacing: 60) {
            ZStack {
                ParticleSystem(rarity: selectedCard.rarity)
                    .frame(width: 300, height: 400)
                    .id(currentCardIndex)
                
                ZStack(alignment: .topTrailing) {
                    HolographicCard(
                        cardImage: selectedCard.name,
                        rarity: selectedCard.rarity,
                        cardNumber: selectedCard.number
                    )
                    
                    if showNewBadge {
                        NewCardBadge()
                            .offset(x: -20, y: -35)
                            .transition(.scale.combined(with: .opacity))
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
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if isTransitioning { return }
                            let translation = gesture.translation.height
                            if translation < 0 {
                                dragOffset = translation
                                showArrowIndicator = false
                            }
                        }
                        .onEnded { gesture in
                            if isTransitioning { return }
                            if dragOffset < -50 {
                                handleCardReveal(selectedCard)
                            } else {
                                withAnimation {
                                    dragOffset = 0
                                    showArrowIndicator = true
                                }
                            }
                        }
                )
                .onTapGesture {
                    handleCardReveal(selectedCard)
                }
                .onAppear {
                    isNewCard = collectionManager.isNewCard(selectedCard)
                    withAnimation(.spring()) {
                        showNewBadge = isNewCard
                    }
                    SoundManager.shared.playSound(for: selectedCard.rarity)
                }
            }
            
            EnhancedRarityButton(rarity: selectedCard.rarity)
        }
    }
    
    private func handleCardReveal(_ selectedCard: BoosterCard) {
        if isTransitioning { return }
        isTransitioning = true
        
        withAnimation(.easeInOut(duration: 0.3)) {
            cardOffset = -UIScreen.main.bounds.height
        }
        
        let newCard = collectionManager.addCard(selectedCard)
        if !drawnCards.contains(where: { $0.name == selectedCard.name }) {
            drawnCards.append(selectedCard)
        }
        
        withAnimation {
            isNewCard = newCard
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            cardOffset = 0
            currentCardIndex += 1
            dragOffset = 0
            showArrowIndicator = true
            isNewCard = false
            if currentCardIndex < 5 {
                currentCard = randomCard()
                SoundManager.shared.playSound(for: currentCard!.rarity)
            } else {
                showSummary = true
            }
            isTransitioning = false
        }
    }
    
    private func randomCard() -> BoosterCard {
        let probabilities: [CardRarity: Double] = [
            .common: 0.7 / 100,
            .rare: 0.25 / 75,
            .epic: 0.1 / 50,
            .legendary: 0.01 / 25,
            .HolyT: 0.001 / 3
        ]

        let weightedCards = allCards.flatMap { card -> [BoosterCard] in
            let weight = probabilities[card.rarity] ?? 0
            let count = Int(weight * 10000)
            return Array(repeating: card, count: count)
        }

        return weightedCards.randomElement() ?? allCards.first!
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
            return Color(white: 0.9)
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
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
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
