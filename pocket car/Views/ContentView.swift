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

struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let angle = sin(animatableData * 4) * 3 // Adjust frequency and amplitude
        let rotation = CGAffineTransform(rotationAngle: angle * .pi / 180)
        return ProjectionTransform(rotation)
    }
}

struct ContentView: View {
    @StateObject var collectionManager = CollectionManager()
    @State private var showExclusiveCarInfo = false
    @State private var showLockedBoosterInfo = false
    @State private var showUpdateAlert = false
    @State private var glowRotationAngle: Double = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isFadingOut: Bool = false
    
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    @AppStorage("remainingFirstBoosters") private var remainingFirstBoosters = 4
    @AppStorage("lastBoosterOpenTime") private var lastBoosterOpenTime: Double = Date().timeIntervalSince1970
    @AppStorage("nextBoosterAvailableTime") private var nextBoosterAvailableTime: Double = Date().timeIntervalSince1970
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var viewSize: ViewSize {
        horizontalSizeClass == .compact ? .compact : .regular
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    BackgroundView()
                    
                    VStack(spacing: viewSize == .compact ? 1 : 5) {
                        CarModelSection(
                            viewSize: viewSize,
                            showExclusiveCarInfo: $showExclusiveCarInfo
                        )
                        
                        Spacer()
                        
                        BoosterSection(
                            viewSize: viewSize,
                            collectionManager: collectionManager,
                            showLockedBoosterInfo: $showLockedBoosterInfo,
                            glowRotationAngle: $glowRotationAngle
                        )
                        
                        ButtonsSection(
                            viewSize: viewSize,
                            collectionManager: collectionManager,
                            glowRotationAngle: $glowRotationAngle
                        )
                        
                        ProgressBarSection(
                            viewSize: viewSize,
                            collectionManager: collectionManager,
                            glowRotationAngle: $glowRotationAngle
                        )
                    }
                    .padding(.horizontal, viewSize == .compact ? 0 : geometry.size.width * 0.1)
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .sheet(isPresented: $showExclusiveCarInfo) {
            ExclusiveCarInfoSheet()
        }
        .sheet(isPresented: $showLockedBoosterInfo) {
            LockedBoosterInfoSheet()
        }
        .alert("Update Available", isPresented: $showUpdateAlert) {
            Button("Update") {
                AppUpdateChecker.shared.openAppStore()
            }
            Button("Later", role: .cancel) { }
        } message: {
            Text("A new version of Pocket Car is available on the App Store.")
        }
        .task {
            if await AppUpdateChecker.shared.checkForUpdate() {
                showUpdateAlert = true
            }
        }
        .onAppear {
            playMusic()
        }
        .onDisappear {
            stopMusic()
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

struct BackgroundView: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [.white, Color(.systemGray5)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct CarModelSection: View {
    let viewSize: ViewSize
    @Binding var showExclusiveCarInfo: Bool
    
    var body: some View {
        VStack(spacing: -50) {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color("mint").opacity(0.1))
                    .frame(height: viewSize == .compact ? 200 : 250)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color("mint").opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color("mint").opacity(0.1), radius: 10, x: 0, y: 5)
                
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white.opacity(1))
                    .frame(height: 170)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                    .offset(y: 30)
                
                VStack {
                    HStack {
                        Spacer()
                        Text("Few days left")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
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
                            .offset(y: 80)
                            .padding(.trailing, 20)
                    }
                    Spacer()
                }
                .zIndex(2)
                
                Button(action: {
                    showExclusiveCarInfo = true
                    HapticManager.shared.impact(style: .medium)
                }) {
                    ZStack {
                        SpriteView(scene: { () -> SKScene in
                            let scene = SKScene()
                            scene.backgroundColor = UIColor.clear
                            
                            let model = SK3DNode(viewportSize: .init(width: 12, height: 12))
                            model.scnScene = {
                                let scnScene = SCNScene(named: "car.obj")!
                                scnScene.background.contents = UIColor.clear
                                
                                let node = scnScene.rootNode.childNodes.first!
                                
                                let rotation = CABasicAnimation(keyPath: "rotation")
                                rotation.fromValue = NSValue(scnVector4: SCNVector4(0, 1, 0, 0))
                                rotation.toValue = NSValue(scnVector4: SCNVector4(0, 1, 0, Float.pi * 2))
                                rotation.duration = 15
                                rotation.repeatCount = .infinity
                                node.addAnimation(rotation, forKey: "rotate")
                                
                                let material = SCNMaterial()
                                material.diffuse.contents = UIImage(named: "texture_diffuse.png")
                                material.metalness.contents = UIImage(named: "texture_metallic.png")
                                material.normal.contents = UIImage(named: "texture_normal.png")
                                material.roughness.contents = UIImage(named: "texture_roughness.png")
                                material.emission.contents = UIColor.white
                                material.emission.intensity = 0.2
                                material.specular.contents = UIColor.white
                                material.shininess = 0.7
                                
                                node.geometry?.materials = [material]
                                
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
            .padding(.horizontal)
        }
        .padding(.top, viewSize == .compact ? 10 : 20)
    }
}

struct BoosterSection: View {
    let viewSize: ViewSize
    let collectionManager: CollectionManager
    @Binding var showLockedBoosterInfo: Bool
    @Binding var glowRotationAngle: Double
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color("mint").opacity(0.1))
                .frame(height: viewSize == .compact ? 350 : 450)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color("mint").opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color("mint").opacity(0.1), radius: 10, x: 0, y: 5)
            
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
                    Button(action: {
                        if StoreManager.shared.boosters == 0 {
                            showLockedBoosterInfo = true
                            HapticManager.shared.impact(style: .medium)
                        }
                    }) {
                        NavigationLink(destination: BoosterOpeningView(collectionManager: collectionManager, boosterNumber: 1)) {
                            ZStack {
                                Image("booster_closed_1")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: viewSize == .compact ? 240 : 300)
                                    .rotation3DEffect(
                                        .degrees(-5),
                                        axis: (x: 0.0, y: 1.0, z: 0.0)
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 5, x: -3, y: 3)
                                
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
                                    .offset(x: -200, y: -200/3)
                                    .blur(radius: 3)
                            }
                            .mask(
                                Image("booster_closed_1")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: viewSize == .compact ? 240 : 300)
                            )
                        }
                        .allowsHitTesting(StoreManager.shared.boosters > 0)
                    }
                    .opacity(StoreManager.shared.boosters == 0 ? 0.5 : 1)
                    
                    Button(action: {
                        if StoreManager.shared.boosters == 0 {
                            showLockedBoosterInfo = true
                            HapticManager.shared.impact(style: .medium)
                        }
                    }) {
                        NavigationLink(destination: BoosterOpeningView(collectionManager: collectionManager, boosterNumber: 2)) {
                            ZStack {
                                Image("booster_closed_2")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: viewSize == .compact ? 240 : 300)
                                    .rotation3DEffect(
                                        .degrees(5),
                                        axis: (x: 0.0, y: 1.0, z: 0.0)
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 5, x: 3, y: 3)
                                
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
                                    .offset(x: -200, y: -200/3)
                                    .blur(radius: 3)
                            }
                            .mask(
                                Image("booster_closed_2")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: viewSize == .compact ? 240 : 300)
                            )
                        }
                        .allowsHitTesting(StoreManager.shared.boosters > 0)
                    }
                    .opacity(StoreManager.shared.boosters == 0 ? 0.5 : 1)
                }
                Spacer()
                
                HStack {
                    if StoreManager.shared.boosters > 0 {
                        Image("gift")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .onAppear {
                                withAnimation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                ) {
                                    // Animation implementation
                                }
                            }
                        HStack(spacing: 4) {
                            Text("\(StoreManager.shared.boosters)")
                                .foregroundColor(.gray)
                            Text("free booster remaining")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    } else if StoreManager.shared.nextFreeBoosterDate != nil {
                        // Booster timer view
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
        .padding(.horizontal, viewSize == .compact ? 12 : 32)
        .padding(.vertical, viewSize == .compact ? 8 : 15)
    }
}

struct ButtonsSection: View {
    let viewSize: ViewSize
    let collectionManager: CollectionManager
    @Binding var glowRotationAngle: Double
    
    var body: some View {
        HStack(spacing: 15) {
            NavigationLink(destination: CollectionView(collectionManager: collectionManager)) {
                buttonView(icon: "", text: "", colors: [.gray.opacity(0.3)], textColor: .gray)
                    .overlay(
                        Image("collection")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                    )
                    .onAppear {
                        withAnimation(
                            Animation
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true)
                        ) {
                            glowRotationAngle = 360
                        }
                    }
            }
            .simultaneousGesture(TapGesture().onEnded {
                HapticManager.shared.impact(style: .medium)
            })
            
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
                                .scaleEffect(1.0)
                                .onAppear {
                                    withAnimation(
                                        .easeInOut(duration: 1.0)
                                        .repeatForever(autoreverses: true)
                                    ) {
                                        // Animation implementation
                                    }
                                }
                        }
                    )
            }
            .simultaneousGesture(TapGesture().onEnded {
                HapticManager.shared.impact(style: .medium)
            })
        }
        .padding(.horizontal, viewSize == .compact ? 12 : 32)
        .padding(.vertical, viewSize == .compact ? 8 : 15)
    }
    
    func buttonView(icon: String, text: String, colors: [Color], textColor: Color) -> some View {
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
}

struct ProgressBarSection: View {
    let viewSize: ViewSize
    let collectionManager: CollectionManager
    @Binding var glowRotationAngle: Double
    
    var body: some View {
        NavigationLink(destination: CollectionProgressView(collectionManager: collectionManager)) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Collection progress")
                        .font(.system(size: viewSize == .compact ? 12 : 16))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(collectionManager.cards.count)/111")
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
                    .onAppear {
                        // Animation implementation
                    }
                    .onDisappear {
                        // Animation implementation
                    }
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
        .padding(.horizontal, viewSize == .compact ? 12 : 32)
        .padding(.bottom, 20)
    }
}

struct ExclusiveCarInfoSheet: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.white, Color(.systemGray5)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                VStack(spacing: 15) {
                    Text("Legendary Model")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.gray)
                    
                    Text("This exclusive car has a mysterious drop rate and isn't part of the regular collection. Get it now - only available this season!")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Button(action: {
                    // Dismiss action
                    HapticManager.shared.impact(style: .medium)
                }) {
                    Text("Got it!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                        .background(
                            ZStack {
                                Capsule()
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.yellow.opacity(0.5), .orange.opacity(0.5)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                }
            }
            .padding(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.opacity(0.95))
        }
        .presentationDetents([.height(250)])
        .presentationBackground(.clear)
    }
}

struct LockedBoosterInfoSheet: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.white, Color(.systemGray5)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 15) {
                Text("Oops! Empty Pockets?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.gray)
                
                Text("Looks like your garage needs a refill! Come back later for a free booster, or hit the shop to grab some coins and keep the collection growing! ")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(action: {
                    // Dismiss action
                    HapticManager.shared.impact(style: .medium)
                }) {
                    Text("I'll be back!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                        .background(
                            ZStack {
                                Capsule()
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.yellow.opacity(0.5), .orange.opacity(0.5)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                }
            }
            .padding(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.opacity(0.95))
        }
        .presentationDetents([.height(250)])
        .presentationBackground(.clear)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
