import SwiftUI
import SceneKit

class PreloadManager: ObservableObject {
    @Published var isLoaded = false
    
    func preloadResources(completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        // Preload 3D Model
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            if let _ = SCNScene(named: "car.obj") {
                print("3D Model preloaded")
            }
            group.leave()
        }
        
        // Preload textures
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            let textures = ["texture_diffuse", "texture_metallic", "texture_normal", "texture_roughness", "shaded"]
            for texture in textures {
                if let _ = UIImage(named: texture) {
                    print("\(texture) preloaded")
                }
            }
            group.leave()
        }
        
        // Preload booster images
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            let boosterImages = ["booster_closed_1", "booster_closed_2"]
            for image in boosterImages {
                if let _ = UIImage(named: image) {
                    print("\(image) preloaded")
                }
            }
            group.leave()
        }
        
        // When all resources are loaded
        group.notify(queue: .main) {
            self.isLoaded = true
            completion()
        }
    }
}