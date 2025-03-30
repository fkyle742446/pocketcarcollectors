import SwiftUI
import SceneKit
import SpriteKit

struct CarModelSection: View {
    let viewSize: ViewSize
    @Binding var showExclusiveCarInfo: Bool
    
    var body: some View {
        VStack(spacing: -50) {
            ZStack {
                // Base rectangle
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color("mint").opacity(0.1))
                    .frame(height: viewSize == .compact ? 200 : 250)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color("mint").opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color("mint").opacity(0.1), radius: 10, x: 0, y: 5)
                
                // Surface rectangle
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white.opacity(1))
                    .frame(height: 170)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                    .offset(y: 30)
                
                CarModel3DView(showExclusiveCarInfo: $showExclusiveCarInfo)
            }
            .padding()
        }
        .padding(.top, viewSize == .compact ? 10 : 20)
    }
}

struct CarModel3DView: View {
    @Binding var showExclusiveCarInfo: Bool
    
    var body: some View {
        Button(action: {
            showExclusiveCarInfo = true
            HapticManager.shared.impact(style: .medium)
        }) {
            ZStack {
                SpriteView(scene: createCarScene(), options: [.allowsTransparency])
                    .frame(height: 150)
                    .background(Color.clear)
                    .offset(y: -20)
                
                VStack {
                    Spacer()
                    Text("only available this season 1")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.yellow, Color.orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .black.opacity(0.2), radius: 4)
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .padding(.bottom, 10)
                }
                .zIndex(3)
            }
        }
    }
    
    private func createCarScene() -> SKScene {
        // Existing 3D scene creation code...
        let scene = SKScene()
        scene.backgroundColor = UIColor.clear
        
        let model = SK3DNode(viewportSize: .init(width: 12, height: 12))
        model.scnScene = {
            let scnScene = SCNScene(named: "car.obj")!
            // Rest of the scene setup...
            return scnScene
        }()
        
        scene.addChild(model)
        return scene
    }
}