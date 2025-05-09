import SwiftUI
import MetalKit

struct MetalCardEffectView: UIViewRepresentable {
    // On pourra ajouter des @Binding ici pour passer des données de SwiftUI au renderer
    // Par exemple:
    // @Binding var touchLocation: CGPoint
    // @Binding var baseCardImage: UIImage?
    let normalizedTouchLocation: CGPoint
    // @Binding var baseCardImage: UIImage? // Example, not used yet

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
        
        // Update initial touch location in renderer
        // context.coordinator.renderer?.updateNormalizedTouchLocation(normalizedTouchLocation)
        // This will be handled by updateUIView on first appearance anyway.

        // Pour optimiser, on peut dire à la vue de ne se redessiner que si nécessaire
        // mtkView.enableSetNeedsDisplay = true 
        // mtkView.isPaused = true // Décommenter si on veut contrôler manuellement le redessin

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Pass the updated touch location to the renderer
        context.coordinator.renderer?.updateNormalizedTouchLocation(normalizedTouchLocation)
        
        // Si enableSetNeedsDisplay = true et isPaused = true, on déclenche un redessin si nécessaire
        // uiView.setNeedsDisplay()
        // If you want to trigger redraws only on change, you might need
        // mtkView.enableSetNeedsDisplay = true
        // mtkView.isPaused = true
        // and then call uiView.setNeedsDisplay() here.
        // For continuous animation (like time-based), isPaused = false is fine.
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

// Default initializer if not providing touchLocation, or make normalizedTouchLocation non-optional
// extension MetalCardEffectView {
//    init() {
//        self.normalizedTouchLocation = CGPoint(x: 0.5, y: 0.5) // Default to center
//    }
// }
// It's better to require it if the shader expects it for EX cards.
// HolographicEXTestView will need to provide a value.
