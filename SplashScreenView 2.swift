import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var cardRotations: [Double] = Array(repeating: 0, count: 6)
    @State private var cardPositions: [(CGFloat, CGFloat)] = [
        (-120, -160), // Top left
        (120, -160),  // Top right
        (-150, 0),    // Middle left
        (150, 0),     // Middle right
        (-120, 160),  // Bottom left
        (120, 160)    // Bottom right
    ]
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            if !isActive {
                VStack {
                    Image("logo") // Make sure to add your logo image to assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250)
                    
                    // Floating cards
                    ZStack {
                        ForEach(0..<6) { index in
                            Image("card_placeholder") // Use a placeholder image from your assets
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 90)
                                .rotationEffect(.degrees(cardRotations[index]))
                                .offset(x: cardPositions[index].0, y: cardPositions[index].1)
                                .onAppear {
                                    withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: true)) {
                                        cardRotations[index] = Double.random(in: -15...15)
                                    }
                                }
                        }
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    self.isActive = true
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
