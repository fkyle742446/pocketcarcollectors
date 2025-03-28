import SwiftUI

struct ParticleSystem: View {
    let rarity: CardRarity
    @State private var particles: [(id: Int, position: CGPoint, opacity: Double)] = []
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(particles.prefix(100), id: \.id) { particle in
                Circle()
                    .fill(haloColor(for: rarity))
                    .frame(width: 3, height: 3)
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
        for i in 0..<100 {
            let angle = Double.random(in: -Double.pi...Double.pi)
            let speed = Double.random(in: 100...300)
            let startPosition = CGPoint(x: 120, y: 170)
            
            var particle = (id: i, position: startPosition, opacity: 0.6)
            particles.append(particle)
            
            withAnimation(.easeOut(duration: 0.8)) {
                let dx = cos(angle) * speed
                let dy = sin(angle) * speed
                particle.position.x += CGFloat(dx)
                particle.position.y += CGFloat(dy)
                particle.opacity = 0
                particles[i] = particle
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
