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

enum ViewSize {
    case compact
    case regular
}

struct ContentView: View {
    @StateObject var collectionManager = CollectionManager()
    @State private var floatingOffset: CGFloat = 0
    @State private var shadowRadius: CGFloat = 15
    @State private var boosterAvailableIn: TimeInterval = 6 * 3600 // 6 hours in seconds
    @State private var timer: Timer? = nil
    @State private var giftAvailableIn: TimeInterval = 1 * 6 // 10 seconds for testing
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isFadingOut: Bool = false
    @State private var glareOffset: CGFloat = -200
    @State private var booster1GlareOffset: CGFloat = -200
    @State private var booster2GlareOffset: CGFloat = -200
    @State private var rotationAngle: Double = 0
    @State private var isCollectionPressed: Bool = false
    
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
    
    @State private var glowRotationAngle: Double = 0
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Background gradient
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

                        VStack(spacing: viewSize == .compact ? 15 : 25) {
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
                                        NavigationLink(destination: BoosterOpeningView(collectionManager: collectionManager, boosterNumber: 1)
                                            .onDisappear {
                                                if isFirstLaunch && remainingFirstBoosters > 0 {
                                                    remainingFirstBoosters -= 1
                                                    if remainingFirstBoosters == 0 {
                                                        isFirstLaunch = false
                                                        lastBoosterOpenTime = Date().timeIntervalSince1970
                                                        nextBoosterAvailableTime = lastBoosterOpenTime + (6 * 3600)
                                                        boosterAvailableIn = 6 * 3600
                                                        
                                                        // Programmer la notification pour 6 heures plus tard
                                                        let content = UNMutableNotificationContent()
                                                        content.title = "Booster Available!"
                                                        content.body = "Your next booster is ready to open!"
                                                        content.sound = .default
                                                        
                                                        // Créer un trigger pour la notification
                                                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 6 * 3600, repeats: false)
                                                        let request = UNNotificationRequest(identifier: "boosterTimer", content: content, trigger: trigger)
                                                        
                                                        // Supprimer les notifications existantes
                                                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["boosterTimer"])
                                                        
                                                        // Ajouter la nouvelle notification
                                                        UNUserNotificationCenter.current().add(request)
                                                    }
                                                } else if !isFirstLaunch {
                                                    lastBoosterOpenTime = Date().timeIntervalSince1970
                                                    nextBoosterAvailableTime = lastBoosterOpenTime + (6 * 3600)
                                                    boosterAvailableIn = 6 * 3600
                                                    
                                                    // Programmer la notification pour 6 heures plus tard
                                                    let content = UNMutableNotificationContent()
                                                    content.title = "Booster Available!"
                                                    content.body = "Your next booster is ready to open!"
                                                    content.sound = .default
                                                    
                                                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 6 * 3600, repeats: false)
                                                    let request = UNNotificationRequest(identifier: "boosterTimer", content: content, trigger: trigger)
                                                    
                                                    // Supprimer les notifications existantes
                                                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["boosterTimer"])
                                                    
                                                    // Ajouter la nouvelle notification
                                                    UNUserNotificationCenter.current().add(request)
                                                }
                                            }
                                        ) {
                                            ZStack {
                                                Image("booster_closed_1")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: boosterHeight)
                                                
                                                // Glare effect for booster 1
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
                                                    .offset(x: booster1GlareOffset)
                                                    .blur(radius: 5)
                                            }
                                            .mask(
                                                Image("booster_closed_1")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: boosterHeight)
                                            )
                                            .shadow(color: .gray.opacity(0.2), radius: 10)
                                        }
                                        .disabled(!isFirstLaunch && boosterAvailableIn > 0)
                                        .onAppear {
                                            withAnimation(Animation.linear(duration: 9.0).repeatForever(autoreverses: false)) {
                                                booster1GlareOffset = 50
                                            }
                                        }

                                        // Second booster with glare
                                        NavigationLink(destination: BoosterOpeningView(collectionManager: collectionManager, boosterNumber: 2)
                                            .onDisappear {
                                                if isFirstLaunch && remainingFirstBoosters > 0 {
                                                    remainingFirstBoosters -= 1
                                                    if remainingFirstBoosters == 0 {
                                                        isFirstLaunch = false
                                                        lastBoosterOpenTime = Date().timeIntervalSince1970
                                                        nextBoosterAvailableTime = lastBoosterOpenTime + (6 * 3600)
                                                        boosterAvailableIn = 6 * 3600
                                                        
                                                        // Programmer la notification pour 6 heures plus tard
                                                        let content = UNMutableNotificationContent()
                                                        content.title = "Booster Available!"
                                                        content.body = "Your next booster is ready to open!"
                                                        content.sound = .default
                                                        
                                                        // Créer un trigger pour la notification
                                                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 6 * 3600, repeats: false)
                                                        let request = UNNotificationRequest(identifier: "boosterTimer", content: content, trigger: trigger)
                                                        
                                                        // Supprimer les notifications existantes
                                                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["boosterTimer"])
                                                        
                                                        // Ajouter la nouvelle notification
                                                        UNUserNotificationCenter.current().add(request)
                                                    }
                                                } else if !isFirstLaunch {
                                                    lastBoosterOpenTime = Date().timeIntervalSince1970
                                                    nextBoosterAvailableTime = lastBoosterOpenTime + (6 * 3600)
                                                    boosterAvailableIn = 6 * 3600
                                                    
                                                    // Programmer la notification pour 6 heures plus tard
                                                    let content = UNMutableNotificationContent()
                                                    content.title = "Booster Available!"
                                                    content.body = "Your next booster is ready to open!"
                                                    content.sound = .default
                                                    
                                                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 6 * 3600, repeats: false)
                                                    let request = UNNotificationRequest(identifier: "boosterTimer", content: content, trigger: trigger)
                                                    
                                                    // Supprimer les notifications existantes
                                                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["boosterTimer"])
                                                    
                                                    // Ajouter la nouvelle notification
                                                    UNUserNotificationCenter.current().add(request)
                                                }
                                            }
                                        ) {
                                            ZStack {
                                                Image("booster_closed_2")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: boosterHeight)
                                                
                                                // Glare effect for booster 2
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
                                                    .offset(x: booster2GlareOffset)
                                                    .blur(radius: 5)
                                            }
                                            .mask(
                                                Image("booster_closed_2")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: boosterHeight)
                                            )
                                            .shadow(color: .gray.opacity(0.2), radius: 10)
                                        }
                                        .disabled(!isFirstLaunch && boosterAvailableIn > 0)
                                        .onAppear {
                                            withAnimation(Animation.linear(duration: 9.0).repeatForever(autoreverses: false)) {
                                                booster2GlareOffset = 50
                                            }
                                        }
                                    }
                                    Spacer()
                                    
                                    // Timer display or instruction text
                                    HStack {
                                        if isFirstLaunch && remainingFirstBoosters > 0 {
                                            Image(systemName: "gift.fill")
                                                .foregroundColor(.gray)
                                            Text("\(remainingFirstBoosters) free boosters remaining")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.gray)
                                        } else if boosterAvailableIn > 0 {
                                            Image(systemName: "clock")
                                                .foregroundColor(.gray)
                                            Text(timeRemainingString())
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.gray)
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
                            .padding(.vertical, viewSize == .compact ? 15 : 25)

                            // Collection and Shop buttons
                            NavigationLink(destination: CollectionView(collectionManager: collectionManager)) {
                                ZStack {
                                    // Animated Glowing border
                                    RoundedRectangle(cornerRadius: 20)
                                        .glow(
                                            fill: .angularGradient(
                                                colors: [.blue, .purple, .red, .orange, .yellow, .blue],
                                                center: .center,
                                                startAngle: .degrees(glowRotationAngle),
                                                endAngle: .degrees(glowRotationAngle + 360)
                                            ),
                                            lineWidth: 3.0,
                                            blurRadius: 6.0
                                        )
                                        .opacity(0.7)
                                    
                                    // Button content
                                    VStack {
                                        Image(systemName: "rectangle.stack.fill")
                                            .font(.system(size: viewSize == .compact ? 30 : 40))
                                        Text("Collection")
                                            .font(.system(size: viewSize == .compact ? 14 : 18, weight: .medium))
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
                            .foregroundColor(.gray)
                            .padding(.horizontal, horizontalPadding)
                            
                            // Bottom progress bar
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
                            .padding(.horizontal, horizontalPadding)
                            .padding(.bottom, 20)
                        }
                    }
                    .padding(.horizontal, viewSize == .compact ? 0 : geometry.size.width * 0.1)
                }
            }
            .onAppear {
                let now = Date().timeIntervalSince1970
                if now < nextBoosterAvailableTime {
                    boosterAvailableIn = nextBoosterAvailableTime - now
                } else {
                    boosterAvailableIn = 0
                }
                withAnimation(
                    .linear(duration: 10)
                    .repeatForever(autoreverses: false)
                ) {
                    glowRotationAngle = 360
                }
                startTimer()
                startGiftTimer()
                playMusic()
            }
            .onDisappear {
                stopMusic()
            }
        }
        // Improved iPad navigation style
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // Timer functionality
    private func startTimer() {
        // Calculer le temps restant en fonction du timestamp sauvegardé
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
                if boosterAvailableIn == 0 {
                    // Notification quand le timer atteint 0
                    let content = UNMutableNotificationContent()
                    content.title = "Booster Available!"
                    content.body = "You can now open a booster"
                    content.sound = .default
                    
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                    
                    UNUserNotificationCenter.current().add(request)
                }
            }
            if giftAvailableIn > 0 {
                giftAvailableIn -= 1
            }
        }
    }
    
    private func startGiftTimer() {
        giftAvailableIn = 10 // Reset gift timer to 10 seconds
    }
    
    private func timeRemainingString() -> String {
        let hours = Int(boosterAvailableIn) / 3600
        let minutes = (Int(boosterAvailableIn) % 3600) / 60
        let seconds = Int(boosterAvailableIn) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func giftTimeRemainingString() -> String {
        let hours = Int(giftAvailableIn) / 3600
        let minutes = (Int(giftAvailableIn) % 3600) / 60
        let seconds = Int(giftAvailableIn) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // Add these functions inside ContentView struct
    private func playMusic() {
        guard let path = Bundle.main.path(forResource: "Background", ofType: "mp3") else {
            print("Could not find Background.mp3")
            return
        }
        let url = URL(fileURLWithPath: path)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1  // Loop indefinitely
            audioPlayer?.volume = 0.5
            audioPlayer?.play()
            
            // Fade in
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
        // Fade out the music
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

#Preview {
    ContentView()
}
