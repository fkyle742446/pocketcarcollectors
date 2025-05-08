
import SwiftUI
import MetalKit

struct MetalCardEffectView: UIViewRepresentable {
    // On pourra ajouter des @Binding ici pour passer des données de SwiftUI au renderer
    // Par exemple:
    // @Binding var touchLocation: CGPoint
    // @Binding var baseCardImage: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        
        // Important: Permettre la transparence de la vue MTKView
        mtkView.isOpaque = false 
        mtkView.backgroundColor = .clear
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)


        guard let renderer = MetalCardEffectRenderer(metalKitView: mtkView) else {
            fatalError("MetalCardEffectRenderer initialization failed")
        }
        mtkView.delegate = renderer
        context.coordinator.renderer = renderer
        
        // Pour optimiser, on peut dire à la vue de ne se redessiner que si nécessaire
        // mtkView.enableSetNeedsDisplay = true 
        // mtkView.isPaused = true // Décommenter si on veut contrôler manuellement le redessin

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Mettre à jour le renderer avec les nouvelles données des @Binding
        // context.coordinator.renderer?.update(touchLocation: touchLocation, image: baseCardImage)
        
        // Si enableSetNeedsDisplay = true et isPaused = true, on déclenche un redessin si nécessaire
        // uiView.setNeedsDisplay()
    }

    class Coordinator: NSObject {
        var parent: MetalCardEffectView
        var renderer: MetalCardEffectRenderer?

        init(_ parent: MetalCardEffectView) {
            self.parent = parent
            super.init()
        }
    }
}
