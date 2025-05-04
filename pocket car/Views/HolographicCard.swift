import SwiftUI

struct HolographicCard: View {
    let cardImage: String
    let rarity: CardRarity
    let cardNumber: Int
    
    @State private var translation: CGSize = .zero
    @State private var isAnimating = false
    @State private var gradientPhase: CGFloat = 0
    @State private var hoverLocation: CGPoint = .zero
    
    private func cardThemeColor(for rarity: CardRarity) -> Color {
        switch rarity {
        case .common:
            return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .rare:
            return Color(red: 0.0, green: 0.48, blue: 0.97)
        case .epic:
            return Color(red: 0.5, green: 0.0, blue: 0.5)
        case .legendary:
            return Color(red: 1, green: 0.84, blue: 0)
        case .HolyT:
            return Color(red: 0.1, green: 0.1, blue: 0.1)
        case .Season1:
            return Color(red: 0.1, green: 0.1, blue: 0.1)
        }
    }
    
    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                translation = value.translation
                hoverLocation = value.location
            }
            .onEnded { _ in
                withAnimation(.spring()) {
                    translation = .zero
                    hoverLocation = .zero
                }
            }
    }
    
    private var holoEffect: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 1, green: 0.2, blue: 0.6).opacity(0.4),
                        Color(red: 1, green: 0.85, blue: 0.3).opacity(0.4),
                        Color(red: 0.2, green: 0.9, blue: 0.3).opacity(0.4),
                        Color(red: 0.2, green: 0.7, blue: 1).opacity(0.4),
                        Color(red: 0.7, green: 0.2, blue: 1).opacity(0.4)
                    ],
                    startPoint: UnitPoint(
                        x: 0.5 + (translation.width / geo.size.width) * 0.2,
                        y: 0.5 + (translation.height / geo.size.height) * 0.2
                    ),
                    endPoint: UnitPoint(
                        x: 1 + (translation.width / geo.size.width) * 0.2,
                        y: 1 + (translation.height / geo.size.height) * 0.2
                    )
                )
                .blendMode(.overlay)
            }
        }
    }
    
    private var glareEffect: some View {
        GeometryReader { geo in
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .white, location: 0),
                    .init(color: .white.opacity(0.3), location: 0.3),
                    .init(color: .clear, location: 0.6)
                ]),
                center: UnitPoint(
                    x: hoverLocation.x / geo.size.width,
                    y: hoverLocation.y / geo.size.height
                ),
                startRadius: 5,
                endRadius: 300
            )
            .opacity(hoverLocation == .zero ? 0 : 1)
            .blendMode(.overlay)
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(cardThemeColor(for: rarity))
                .overlay(
                    Group {
                        if rarity == .HolyT {
                            CarbonPatternView()
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                    }
                )
                .frame(width: 250, height: 350)
            
            if rarity != .common {
                holoEffect
                    .mask(
                        RoundedRectangle(cornerRadius: 15)
                            .frame(width: 250, height: 350)
                    )
            }
            
            VStack(spacing: 0) {
                HStack {
                    Text(cardImage)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.leading, 15)
                    
                    Spacer()
                    
                    Text("\(rarity.rawValue.uppercased())")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.trailing, 15)
                }
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.2))
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.9))
                    
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(cardThemeColor(for: rarity), lineWidth: 2)
                        .padding(4)
                    
                    Image(cardImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 220, height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(8)
                }
                .frame(width: 240, height: 260)
                .padding(.vertical, 10)
                
                HStack {
                    Text("POCKET CAR ILLUSTRATION ")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                    
                    Spacer()
                    
                    Text("№ \(cardNumber)/250")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.3))
                        )
                }
                .padding(.horizontal, 15)
            }
            
            glareEffect
                .mask(
                    RoundedRectangle(cornerRadius: 15)
                        .frame(width: 250, height: 350)
                )
            
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(
                    LinearGradient(
                        colors: rarity == .HolyT ? [
                            Color(white: 0.9),
                            Color(white: 0.6),
                            Color(white: 0.9)
                        ] : [
                            cardThemeColor(for: rarity).opacity(0.8),
                            .white.opacity(0.7),
                            cardThemeColor(for: rarity).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
        }
        .frame(width: 250, height: 350)
        .rotation3DEffect(
            .degrees(Double(translation.height / 10)),
            axis: (x: -1, y: translation.width / 100, z: 0)
        )
        .gesture(drag)
    }
}

struct CarbonPatternView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                Path { path in
                    let size: CGFloat = 8
                    let rows = Int(geo.size.height / size) + 1
                    let cols = Int(geo.size.width / size) + 1
                    
                    for row in -1...rows {
                        for col in -1...cols {
                            let x = CGFloat(col) * size
                            let y = CGFloat(row) * size
                            
                            path.move(to: CGPoint(x: x, y: y))
                            path.addLine(to: CGPoint(x: x + size, y: y + size))
                            
                            path.move(to: CGPoint(x: x + size, y: y))
                            path.addLine(to: CGPoint(x: x, y: y + size))
                            
                            path.move(to: CGPoint(x: x + size/2, y: y))
                            path.addQuadCurve(
                                to: CGPoint(x: x + size, y: y + size/2),
                                control: CGPoint(x: x + size * 0.75, y: y + size * 0.25)
                            )
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
                
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: UnitPoint(x: phase, y: 0),
                    endPoint: UnitPoint(x: phase + 1, y: 1)
                )
                .blendMode(.overlay)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 4
                        )
                    )
                    .frame(width: 8, height: 8)
                    .blendMode(.overlay)
                    .offset(x: phase * geo.size.width, y: 0)
            }
        }
        .onAppear {
            withAnimation(
                .linear(duration: 3)
                .repeatForever(autoreverses: true)
            ) {
                phase = 1
            }
        }
        .background(Color.black.opacity(0.9))
        .mask(
            LinearGradient(
                colors: [
                    .black,
                    .black.opacity(0.9),
                    .black.opacity(0.9),
                    .black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
