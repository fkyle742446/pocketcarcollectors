import SwiftUI
import AVFoundation
import SceneKit
import SpriteKit
import UserNotifications
import StoreKit

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
    @State private var shakeOffset: CGFloat = 0
    @State private var shakeAngle: Double = 0
    @State private var shakeTimer: Timer?
    @State private var coinAngle: Double = 0
    @State private var coinScale: CGFloat = 1.0
    @State private var progressValue: Double = 0
    @State private var booster1Rotation: Double = -5
    @State private var booster2Rotation: Double = 5
    @State private var showExclusiveCarInfo = false
    @State private var showLockedBoosterInfo = false
    @State private var showUpdateAlert = false
    
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
    
    @StateObject private var reviewManager = ReviewManager.shared
    
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
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                                    .offset(y: 30)

                                // ADD: Few days left text positioned on top of the rectangle
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
                                        // 3D Model View
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
                                        
                                        // Season availability text at the bottom
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
                                        // First booster with glare and 3D rotation
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
                                                        .frame(height: boosterHeight)
                                                        // ADD: 3D rotation effect
                                                        .rotation3DEffect(
                                                            .degrees(booster1Rotation),
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
                                                        .offset(x: booster1GlareOffset, y: booster1GlareOffset/3)
                                                        .blur(radius: 3)
                                                }
                                                .mask(
                                                    Image("booster_closed_1")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(height: boosterHeight)
                                                )
                                            }
                                            .allowsHitTesting(StoreManager.shared.boosters > 0)
                                        }
                                        .opacity(StoreManager.shared.boosters == 0 ? 0.5 : 1)

                                        // Second booster with 3D rotation
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
                                                        .frame(height: boosterHeight)
                                                        // ADD: 3D rotation effect
                                                        .rotation3DEffect(
                                                            .degrees(booster2Rotation),
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
                                                        .offset(x: booster2GlareOffset, y: booster2GlareOffset/3)
                                                        .blur(radius: 3)
                                                }
                                                .mask(
                                                    Image("booster_closed_2")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(height: boosterHeight)
                                                )
                                            }
                                            .allowsHitTesting(StoreManager.shared.boosters > 0)
                                        }
                                        .opacity(StoreManager.shared.boosters == 0 ? 0.5 : 1)
                                    }
                                    Spacer()
                                    
                                    // Timer display or instruction text
                                    HStack {
                                        if StoreManager.shared.boosters > 0 {
                                            Image("gift")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 30, height: 30)
                                                .rotationEffect(.degrees(shakeAngle))
                                                .onAppear {
                                                    withAnimation(
                                                        .easeInOut(duration: 0.8)
                                                        .repeatForever(autoreverses: true)
                                                    ) {
                                                        shakeAngle = 8
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
                                                    .scaleEffect(coinScale)
                                                    .rotationEffect(.degrees(coinAngle))
                                                    .onAppear {
                                                        withAnimation(
                                                            .easeInOut(duration: 1.0)
                                                            .repeatForever(autoreverses: true)
                                                        ) {
                                                            coinScale = 1.1
                                                        }
                                                    }
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
                                        Text("Completion of collection")
                                            .font(.system(size: viewSize == .compact ? 12 : 16))
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("\(collectionManager.cards.count)/111")
                                            .font(.system(size: viewSize == .compact ? 12 : 16))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    ProgressView(value: progressValue, total: 108)
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
                                            progressValue = 0
                                            withAnimation(.easeOut(duration: 3.0)) {
                                                progressValue = Double(collectionManager.cards.count)
                                            }
                                        }
                                        .onDisappear {
                                            progressValue = 0
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
        .onChange(of: collectionManager.cards.count) { _, _ in
            let progress = Double(collectionManager.cards.count) / 111.0
            ReviewManager.shared.checkMilestone(collectionProgress: progress)
        }
        .alert("Collection Milestone! 🎉", isPresented: $reviewManager.showMilestoneAlert) {
            Button("Rate Us") {
                reviewManager.requestReview()
            }
            Button("Continue", role: .cancel) { }
        } message: {
            Text("Congratulations! You've collected \(reviewManager.currentMilestone)% of all cars! Would you like to rate your experience?")
        }
        .task {
            if await AppUpdateChecker.shared.checkForUpdate() {
                showUpdateAlert = true
            }
            let progress = Double(collectionManager.cards.count) / 111.0
            ReviewManager.shared.checkAndRequestReview(collectionProgress: progress)
        }
        .alert("Update Available", isPresented: $showUpdateAlert) {
            Button("Update") {
                AppUpdateChecker.shared.openAppStore()
            }
            Button("Later", role: .cancel) { }
        } message: {
            Text("A new version of Pocket Car is available on the App Store.")
        }
        .sheet(isPresented: $showExclusiveCarInfo) {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.white, Color(.systemGray5)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Content
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
                        showExclusiveCarInfo = false
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
        .sheet(isPresented: $showLockedBoosterInfo) {
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
                    
                    Text("Looks like your garage needs a refill! Come back later for a free booster, or hit the shop to grab some coins and keep the collection growing! 🚗✨")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button(action: {
                        showLockedBoosterInfo = false
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
