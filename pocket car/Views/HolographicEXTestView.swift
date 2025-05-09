import SwiftUI

struct HolographicEXTestView: View {
    // États pour contrôler l'effet (si on ajoute des uniforms plus tard)
    // @State private var touchLocation: CGPoint = .zero
    // @State private var someParameter: Float = 0.5
    @State private var touchLocationForTest: CGPoint = CGPoint(x: 0.5, y: 0.5) // Default to center

    var body: some View {
        ZStack {
            // Exemple: Image de fond d'une carte
            Image("Ferrari Enzo") // Remplace par une vraie image de tes assets
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 250, height: 350)
                .opacity(0.5) // Pour voir l'effet Metal par-dessus

            MetalCardEffectView(normalizedTouchLocation: touchLocationForTest)
                // Passer les bindings si on en a
                // .touchLocation($touchLocation)
                .frame(width: 250, height: 350) // Même taille que la carte
                .clipShape(RoundedRectangle(cornerRadius: 15)) // Pour avoir les coins arrondis
                .allowsHitTesting(false) // Pour que l'effet soit visuel mais n'intercepte pas les taps destinés à la carte dessous si besoin
                // OR, if you want to test drag directly on MetalCardEffectView (not recommended if it's usually inside HolographicCard)
                // .gesture(
                //     DragGesture(minimumDistance: 0)
                //         .onChanged { value in
                //             // Normalize based on the frame of MetalCardEffectView (250x350)
                //             let normalizedX = max(0.0, min(1.0, value.location.x / 250.0))
                //             let normalizedY = max(0.0, min(1.0, value.location.y / 350.0))
                //             self.touchLocationForTest = CGPoint(x: normalizedX, y: normalizedY)
                //         }
                //         .onEnded { _ in
                //             self.touchLocationForTest = CGPoint(x: 0.5, y: 0.5) // Reset to center
                //         }
                // )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray) // Un fond pour la page de test
        .edgesIgnoringSafeArea(.all)
        // Example gesture on the ZStack if MetalCardEffectView has allowsHitTesting(false)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Assuming the ZStack is roughly the size of the card area for this test
                    // Or get geometry if the ZStack is full screen.
                    // For simplicity, let's assume the drag location is somewhat relevant to the card.
                    // This is just for testing the shader.
                    // For a 250x350 card centered in the screen, this value.location would need careful mapping.
                    // It's easier to test through HolographicCard.
                    // For now, let's just make the test view pass a static or slightly animated value
                    // if not adding a complex gesture here.
                    // To make it animated for testing without drag:
                    // self.touchLocationForTest = CGPoint(x: 0.5 + 0.25 * cos(Date().timeIntervalSince1970),
                    //                                    y: 0.5 + 0.25 * sin(Date().timeIntervalSince1970))
                }
        )
        // Example of just making it cycle for testing:
        // .onAppear {
        //     Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
        //         let time = Date().timeIntervalSince1970
        //         self.touchLocationForTest = CGPoint(
        //             x: 0.5 + 0.25 * cos(time * 1.5),
        //             y: 0.5 + 0.25 * sin(time * 2.0)
        //         )
        //     }
        // }
    }
}

struct HolographicEXTestView_Previews: PreviewProvider {
    static var previews: some View {
        HolographicEXTestView()
    }
}
