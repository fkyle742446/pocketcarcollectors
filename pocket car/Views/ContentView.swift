import SwiftUI
import AVFoundation
import SceneKit
import SpriteKit
import UserNotifications

// Add the glow extension
extension View where Self: Shape {
    func glow(
        fill: some ShapeStyle,
        lineWidth: Double,
        blurRadius: Double = 8.0,
        lineCap: CGLineCap = .round
    ) -> some View {
        self
            .stroke(style: StrokeStyle(lineWidth: lineWidth / 2, lineCap: lineCap))
            .fill(fill)
            .overlay {
                self
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: lineCap))
                    .fill(fill)
                    .blur(radius: blurRadius)
            }
            .overlay {
                self
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: lineCap))
                    .fill(fill)
                    .blur(radius: blurRadius / 2)
            }
    }
}

class HapticManager {
    static let shared = HapticManager()
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

enum ViewSize {
    case compact
    case regular
}

struct ContentView: View {
    @StateObject var collectionManager = CollectionManager()
    @State private var floatingOffset: CGFloat = 0
    @State private var shadowRadius: CGFloat = 15
    @State private var boosterAvailableIn: TimeInterval = 6 * 3600
    @State private var timer: Timer? = nil
    @State private var giftAvailableIn: TimeInterval = 1 * 6
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isFadingOut: Bool = false
    @State private var glareOffset: CGFloat = -200
    @State private var booster1GlareOffset: CGFloat = -200
    @State private var booster2GlareOffset: CGFloat = -200
    @State private var rotationAngle: Double = 0
    @State private var isCollectionPressed: Bool = false
    @State private var glowRotationAngle: Double = 0
    
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    @AppStorage("remainingFirstBoosters") private var remainingFirstBoosters = 4
    @AppStorage("lastBoosterOpenTime") private var lastBoosterOpenTime: Double = Date().timeIntervalSince1970
    @AppStorage("nextBoosterAvailableTime") private var nextBoosterAvailableTime: Double = Date().timeIntervalSince1970
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var viewSize: ViewSize {
        horizontalSizeClass == .compact ? .compact : .regular
    }
    
    private var logoHeight: CGFloat {
        viewSize == .compact ? 60 : 100
    }
    
    private var boosterHeight: CGFloat {
        viewSize == .compact ? 240 : 300
    }
    
    private var mainSpacing: CGFloat {
        viewSize == .compact ? -25 : 20
    }
    
    private var horizontalPadding: CGFloat {
        viewSize == .compact ? 12 : 32
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [.white, Color(.systemGray5)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    VStack {
                        Spacer()
                    }

                    VStack(spacing: viewSize == .compact ? 1 : 5) {
                        // Top logo section - Adjust size for iPad
                        VStack(spacing: -50) {
                            // Logo with glare effect
                            ZStack {
                                Image("logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: logoHeight)
                                
                                // Glare effect
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                .clear,
                                                .white.opacity(0.5),
                                                .clear
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 50)
                                    .offset(x: glareOffset)
                                    .blur(radius: 5)
                            }
                            .mask(
                                Image("logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: logoHeight)
                            )
                            .onAppear {
                                withAnimation(Animation.linear(duration: 15.0).repeatForever(autoreverses: false)) {
                                    glareOffset = 200
                                }
                                
                                // Request notification permission when view appears
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { success, error in
                                    if let error = error {
                                        print(error.localizedDescription)
                                    }
                                }
                            }
                            
                            // 3D Model View with Legendary Halo
                            ZStack {
                                // Base rectangle with depth effect
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
                                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                                
                                    .offset(y: 30) // Added offset to move down

                                
                                // 3D Model positioned above halo
                                VStack(spacing: -80) {
                                    // 3D Model
                                    SpriteView(scene: { () -> SKScene in
                                        let scene = SKScene()
                                        scene.backgroundColor = UIColor.clear
                                        
                                        let model = SK3DNode(viewportSize: .init(width: 12, height: 12))
                                        model.scnScene = {
                                            let scnScene = SCNScene(named: "car.obj")!
                                            scnScene.background.contents = UIColor.clear
                                            
                                            let node = scnScene.rootNode.childNodes.first!
                                            
                                            // Add rotation animation
                                            let rotation = CABasicAnimation(keyPath: "rotation")
                                            rotation.fromValue = NSValue(scnVector4: SCNVector4(0, 1, 0, 0))
                                            rotation.toValue = NSValue(scnVector4: SCNVector4(0, 1, 0, Float.pi * 2))
                                            rotation.duration = 15
                                            rotation.repeatCount = .infinity
                                            node.addAnimation(rotation, forKey: "rotate")
                                            
                                            
                                            // Ajouter les textures au matériau
                                                    let material = SCNMaterial()
                                                    material.diffuse.contents = UIImage(named: "texture_diffuse.png") // Texture diffuse
                                                    material.metalness.contents = UIImage(named: "texture_metallic.png") // Texture métallique
                                                    material.normal.contents = UIImage(named: "texture_normal.png") // Carte de normales
                                                    material.roughness.contents = UIImage(named: "texture_roughness.png") // Rugosité
                                            
                                            // Ajouter une émission pour rendre l'objet plus lumineux
                                            material.emission.contents = UIColor.white // Couleur émise
                                            material.emission.intensity = 0.2 // Intensité de la lumière émise
                                            
                                            // Augmenter la réflexion spéculaire
                                            material.specular.contents = UIColor.white
                                            material.shininess = 0.7 // Contrôle la brillance
                                    
                                            
                                            
                                            // Ajouter la texture shaded comme diffuse alternative (si besoin)
                                                        let shadedMaterial = SCNMaterial()
                                                        shadedMaterial.diffuse.contents = UIImage(named: "shaded.png") // Shaded texture
                                            
                                            // Appliquer le matériau à la géométrie
                                                   node.geometry?.materials = [material]

                                            
                                            // Add camera to the scene
                                            let cameraNode = SCNNode()
                                            cameraNode.camera = SCNCamera()
                                            cameraNode.position = SCNVector3(x: -1.6, y: 0, z: 14)
                                            scnScene.rootNode.addChildNode(cameraNode)
                                            
                                            return scnScene
                                        }()
                                        
                                        scene.addChild(model)
                                        return scene
                                    }(), options: [.allowsTransparency])
                                    .frame(height: 150)
                                    .background(Color.clear)
                                    .zIndex(2) // Ensure model is above halo
                                    
                                    // Legendary halo effect positioned below model
                                                  ZStack {
                                                      // Base glow
                                                      RoundedRectangle(cornerRadius: 25)
                                                          .fill(
                                                              RadialGradient(
                                                                  gradient: Gradient(colors: [
                                                                    Color.white.opacity(0.1),
                                                                    Color.white.opacity(0.1),
                                                                      Color.clear
                                                                  ]),
                                                                  center: .center,
                                                                  startRadius: 80,
                                                                  endRadius: 150
                                                              )
                                                          )
                                                          .frame(width: 300, height: 200)
                                                          .blur(radius: 45)
                                                   
                                                      // Animated rays
                                                      ForEach(0..<10) { i in
                                                          Rectangle()
                                                              .fill(
                                                                  LinearGradient(
                                                                      colors: [
                                                                          Color.yellow.opacity(0.6),
                                                                          Color.orange.opacity(0.3),
                                                                          Color.clear
                                                                      ],
                                                                      startPoint: .center,
                                                                      endPoint: .trailing
                                                                  )
                                                              )
                                                              .frame(width: 200, height: 0.2)
                                                              .rotationEffect(.degrees(Double(i) * 45))
                                                              .blur(radius: 5)
                                                      }
                                                  }
                                                  .offset(y: -0)
                                                  .zIndex(1)
                                    
                                    
                                    
                                    // Season availability bubble
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
                                                      .offset(y: -15)
                                                      .zIndex(3)
                                }
                                .padding(0)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, viewSize == .compact ? 10 : 20)
                        
                        Spacer()

                        VStack(spacing: viewSize == .compact ? 8 : 15) {
                            // Boosters section - Adjust for iPad
                            ZStack {
                                // Base rectangle with depth effect
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color("mint").opacity(0.1))
                                    .frame(height: viewSize == .compact ? 350 : 450)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color("mint").opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: Color("mint").opacity(0.1), radius: 10, x: 0, y: 5)
                                
                                // Surface rectangle
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.white.opacity(1))
                                    .frame(height: viewSize == .compact ? 320 : 420)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                                    .offset(y: 0)
                                
                                VStack {
                                    Spacer()
                                    HStack(spacing: viewSize == .compact ? 30 : 50) {
                                        // First booster with glare
                                        NavigationLink(destination: BoosterOpeningView(collectionManager: collectionManager, boosterNumber: 1)) {
                                            ZStack {
                                                Image("booster_closed_1")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: boosterHeight)
                                                
                                                Rectangle()
                                                    .fill(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                .clear,
                                                                .white.opacity(0.01),
                                                                .white.opacity(0.15),
                                                                .white.opacity(0.01),
                                                                .clear
                                                            ]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 100)
                                                    .rotationEffect(.degrees(-65))
                                                    .offset(x: booster1GlareOffset, y: booster1GlareOffset/3)
                                                    .blur(radius: 3)
                                            }
                                            .mask(
                                                Image("booster_closed_1")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: boosterHeight)
                                            )
                                            .shadow(color: .gray.opacity(0.2), radius: 10)
                                        }
                                        .simultaneousGesture(TapGesture().onEnded {
                                            HapticManager.shared.impact(style: .medium)
                                        })
                                        .disabled(StoreManager.shared.boosters == 0)
                                        .opacity(StoreManager.shared.boosters == 0 ? 0.5 : 1)
                                        .onAppear {
                                            withAnimation(
                                                Animation
                                                    .easeInOut(duration: 4.0)
                                                    .repeatForever(autoreverses: true)
                                            ) {
                                                booster1GlareOffset = 150
                                            }
                                        }

                                        // Second booster
                                        NavigationLink(destination: BoosterOpeningView(collectionManager: collectionManager, boosterNumber: 2)) {
                                            ZStack {
                                                Image("booster_closed_2")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: boosterHeight)
                                                
                                                Rectangle()
                                                    .fill(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                .clear,
                                                                .white.opacity(0.01),
                                                                .white.opacity(0.15),
                                                                .white.opacity(0.01),
                                                                .clear
                                                            ]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 100)
                                                    .rotationEffect(.degrees(-65))
                                                    .offset(x: booster2GlareOffset, y: booster2GlareOffset/3)
                                                    .blur(radius: 3)
                                            }
                                            .mask(
                                                Image("booster_closed_2")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: boosterHeight)
                                            )
                                            .shadow(color: .gray.opacity(0.2), radius: 10)
                                        }
                                        .simultaneousGesture(TapGesture().onEnded {
                                            HapticManager.shared.impact(style: .medium)
                                        })
                                        .disabled(StoreManager.shared.boosters == 0)
                                        .opacity(StoreManager.shared.boosters == 0 ? 0.5 : 1)
                                        .onAppear {
                                            withAnimation(
                                                Animation
                                                    .easeInOut(duration: 3.5)
                                                    .repeatForever(autoreverses: true)
                                                    .delay(2.0)
                                            ) {
                                                booster2GlareOffset = 150
                                            }
                                        }
                                    }
                                    Spacer()
                                    
                                    // Timer display or instruction text
                                    HStack {
                                        if StoreManager.shared.boosters > 0 {
                                            Image("gift")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 30, height: 30)
                                            Text("\(StoreManager.shared.boosters) free boosters remaining")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.gray)
                                        } else if StoreManager.shared.nextFreeBoosterDate != nil {
                                            BoosterTimerView(storeManager: StoreManager.shared)
                                        } else {
                                            Image(systemName: "hand.tap")
                                                .foregroundColor(.gray)
                                            Text("Click on a booster")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 15)
                                    .background(
                                        ZStack {
                                            Capsule()
                                                .glow(
                                                    fill: .angularGradient(
                                                        colors: [.blue, .purple, .red, .orange, .yellow, .blue],
                                                        center: .center,
                                                        startAngle: .degrees(glowRotationAngle),
                                                        endAngle: .degrees(glowRotationAngle + 360)
                                                    ),
                                                    lineWidth: 2.0,
                                                    blurRadius: 4.0
                                                )
                                                .opacity(0.4)
                                            
                                            Capsule()
                                                .fill(Color.white)
                                        }
                                    )
                                    .padding(.bottom, 0)
                                }
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.vertical, viewSize == .compact ? 8 : 15)

                            // Collection and Shop buttons
                            HStack(spacing: 15) {
                                // Collection Button
                                NavigationLink(destination: CollectionView(collectionManager: collectionManager)) {
                                    buttonView(icon: "rectangle.stack.fill", text: "Collection", colors: [.gray.opacity(0.3)], textColor: .gray)
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    HapticManager.shared.impact(style: .medium)
                                })
                                
                                // Shop Button
                                NavigationLink(destination: ShopView(collectionManager: collectionManager, storeManager: StoreManager.shared)) {
                                    buttonView(icon: "", text: "", colors: [.gray.opacity(0.3)], textColor: .gray)
                                        .overlay(
                                            HStack(spacing: 4) {
                                                Text("\(collectionManager.coins)")
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.gray)
                                                Image("coin")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 50, height: 50)
                                            }
                                        )
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    HapticManager.shared.impact(style: .medium)
                                })
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.vertical, viewSize == .compact ? 8 : 15)

                            // Bottom progress bar
                            NavigationLink(destination: CollectionProgressView(collectionManager: collectionManager)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("108 cards in collection")
                                            .font(.system(size: viewSize == .compact ? 12 : 16))
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("\(collectionManager.cards.count)/108")
                                            .font(.system(size: viewSize == .compact ? 12 : 16))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    ProgressView(value: Double(collectionManager.cards.count), total: 108)
                                        .frame(height: 6)
                                        .tint(
                                            LinearGradient(
                                                colors: [Color.yellow, Color.orange],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .background(Color.white)
                                }
                                .padding(15)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .glow(
                                                fill: .angularGradient(
                                                    colors: [.blue, .purple, .red, .orange, .yellow, .blue],
                                                    center: .center,
                                                    startAngle: .degrees(glowRotationAngle),
                                                    endAngle: .degrees(glowRotationAngle + 360)
                                                ),
                                                lineWidth: 2.0,
                                                blurRadius: 4.0
                                            )
                                            .opacity(0.4)
                                        
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.white)
                                    }
                                )
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                HapticManager.shared.impact(style: .medium)
                            })
                            .padding(.horizontal, horizontalPadding)
                            .padding(.bottom, 20)
                        }
                    }
                    .padding(.horizontal, viewSize == .compact ? 0 : geometry.size.width * 0.1)
                }
            }
            // Improved iPad navigation style
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .onAppear {
            startTimer()
            playMusic()
        }
        .onDisappear {
            stopMusic()
        }
    }
    
    private func buttonView(icon: String, text: String, colors: [Color], textColor: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .glow(
                    fill: .angularGradient(
                        colors: colors,
                        center: .center,
                        startAngle: .degrees(glowRotationAngle),
                        endAngle: .degrees(glowRotationAngle + 360)
                    ),
                    lineWidth: 3.0,
                    blurRadius: 6.0
                )
                .opacity(0.7)
            
            VStack {
                Image(systemName: icon)
                    .font(.system(size: viewSize == .compact ? 30 : 40))
                    .foregroundColor(textColor)
                Text(text)
                    .font(.system(size: viewSize == .compact ? 14 : 18, weight: .medium))
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: viewSize == .compact ? 60 : 100)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
            )
        }
    }
    
    private func startTimer() {
        let now = Date().timeIntervalSince1970
        if now < nextBoosterAvailableTime {
            boosterAvailableIn = nextBoosterAvailableTime - now
        } else {
            boosterAvailableIn = 0
        }
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if boosterAvailableIn > 0 {
                boosterAvailableIn -= 1
            }
            if giftAvailableIn > 0 {
                giftAvailableIn -= 1
            }
        }
    }
    
    private func playMusic() {
        guard let path = Bundle.main.path(forResource: "Background", ofType: "mp3") else {
            print("Could not find Background.mp3")
            return
        }
        let url = URL(fileURLWithPath: path)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 0.5
            audioPlayer?.play()
            
            audioPlayer?.volume = 0
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                if let player = audioPlayer, player.volume < 0.5 {
                    player.volume += 0.1
                } else {
                    timer.invalidate()
                }
            }
        } catch {
            print("Error playing music: \(error.localizedDescription)")
        }
    }
    
    private func stopMusic() {
        isFadingOut = true
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if let player = audioPlayer, player.volume > 0 {
                player.volume -= 0.1
            } else {
                timer.invalidate()
                audioPlayer?.stop()
                isFadingOut = false
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
