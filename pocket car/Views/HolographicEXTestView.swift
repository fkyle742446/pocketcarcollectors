
import SwiftUI

struct HolographicEXTestView: View {
    // États pour contrôler l'effet (si on ajoute des uniforms plus tard)
    // @State private var touchLocation: CGPoint = .zero
    // @State private var someParameter: Float = 0.5

    var body: some View {
        ZStack {
            // Exemple: Image de fond d'une carte
            Image("votre_image_de_carte_test") // Remplace par une vraie image de tes assets
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 250, height: 350)
                .opacity(0.5) // Pour voir l'effet Metal par-dessus

            MetalCardEffectView()
                // Passer les bindings si on en a
                // .touchLocation($touchLocation)
                .frame(width: 250, height: 350) // Même taille que la carte
                .clipShape(RoundedRectangle(cornerRadius: 15)) // Pour avoir les coins arrondis
                .allowsHitTesting(false) // Pour que l'effet soit visuel mais n'intercepte pas les taps destinés à la carte dessous si besoin
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray) // Un fond pour la page de test
        .edgesIgnoringSafeArea(.all)
        // Gestures pour interagir avec l'effet plus tard (par exemple, pour l'effet miroir)
        // .gesture(
        //     DragGesture(minimumDistance: 0)
        //         .onChanged { value in
        //             self.touchLocation = value.location
        //         }
        //         .onEnded { _ in
        //             self.touchLocation = .zero // Ou une position neutre
        //         }
        // )
    }
}

struct HolographicEXTestView_Previews: PreviewProvider {
    static var previews: some View {
        HolographicEXTestView()
    }
}
