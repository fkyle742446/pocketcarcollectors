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

enum DeepLink {
    case legendaryCarPopup
    
    init?(url: URL) {
        print(" Parsing URL: \(url.absoluteString)")
        switch url.absoluteString {
        case let str where str.contains("pocketcar://legendary-car"):
            print(" Matched legendary car URL")
            self = .legendaryCarPopup
        default:
            print(" No URL match")
            return nil
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView: View {
    @StateObject var collectionManager = CollectionManager()
    @State private var shadowRadius: CGFloat = 15
    @State private var boosterAvailableIn: TimeInterval = 6 * 3600
    @State private var timer: Timer? = nil
    @State private var giftAvailableIn: TimeInterval = 1 * 6
    @State private var glareOffset: CGFloat = -250
    @State private var booster1GlareOffset: CGFloat = -250
    @State private var booster2GlareOffset: CGFloat = -250
    @State private var rotationAngle: Double = 0
    @State private var isCollectionPressed: Bool = false
    @State private var glowRotationAngle: Double = 45
    @State private var shakeOffset: CGFloat = 0
    @State private var shakeAngle: Double = 0
    @State private var shakeTimer: Timer?
    @State private var coinAngle: Double = 0
    @State private var coinScale: CGFloat = 1.0
    @State private var progressValue: Double = 0
    @State private var showExclusiveCarInfo = false
    @State private var showLockedBoosterInfo = false
    @State private var showUpdateAlert = false
    @State private var navigateToBooster = false
    @State private var selectedMilestone: MilestoneIdentifier? = nil
    
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    @AppStorage("remainingFirstBoosters") private var remainingFirstBoosters = 4
    @AppStorage("lastBoosterOpenTime") private var lastBoosterOpenTime: Double = Date().timeIntervalSince1970
    @AppStorage("nextBoosterAvailableTime") private var nextBoosterAvailableTime: Double = Date().timeIntervalSince1970
    
    @AppStorage("nextDailyQuestTime") private var nextDailyQuestTime: Double = Date().timeIntervalSince1970
    @AppStorage("dailyQuestSpinsCount") private var dailyQuestSpinsCount: Int = 0
    @AppStorage("isCurrentDailyQuestRewardClaimed") private var isCurrentDailyQuestRewardClaimed: Bool = false
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var waveOffset = 0.0
    @State private var waveAnimation = false
    
    @State private var breathingProgress: Double = 0
    @State private var isAnimating = false // Used for quest button glow and progress bar breathing
    
    @State private var hasAppeared = false
    
    @State private var showMilestoneRewardPopup = false
    @State private var currentMilestoneForPopup: CollectionProgressView.MilestoneToDisplay? = nil
    
    @State private var showDailyQuestPopup = false
    @State private var currentDailyQuestDisplayInfo: DailyQuestDisplayInfo? = nil
    
    private var viewSize: ViewSize {
        horizontalSizeClass == .compact ? .compact : .regular
    }
    
    private var logoHeight: CGFloat {
        viewSize == .compact ? 60 : 100
    }
    
    private var boosterHeight: CGFloat {
        viewSize == .compact ? 280 : 340
    }
    
    private var mainSpacing: CGFloat {
        viewSize == .compact ? -25 : 20
    }
    
    private var horizontalPadding: CGFloat {
        viewSize == .compact ? 12 : 32
    }
    
    private struct Milestone: Identifiable {
        let id = UUID() // Keep UUID for ForEach
        let identifier: MilestoneIdentifier // Store the enum case directly
        var isReached: Bool

        // Computed property for progress based on the identifier
        var progress: Double {
            switch identifier {
            case .progress04: return 0.04
            case .progress25: return 0.25
            case .progress50: return 0.50
            case .progress75: return 0.75
            case .progress100: return 1.00
            }
        }
        
        // Computed property for icon based on the identifier
        var icon: String {
            // This centralizes icon logic for local milestones
            switch identifier {
            case .progress04: return "gift.stack.fill" // For 5 boosters
            case .progress25: return "coin"
            case .progress50: return "car_fill_badge_plus" // For Ferrari FXX-K
            case .progress75: return "coin" // For 500 coins (previously 100% reward)
            case .progress100: return "star.circle.fill" // For LaFerrari Holy Trinity (previously 75% reward)
            }
        }
    }
    
    // This ensures order and direct mapping.
    @State private var milestones: [Milestone] = MilestoneIdentifier.allCases
        .sorted { difficultéÀCalculerGauche, difficultéÀCalculerDroite in // Ensure the order matches the visual progress bar
            // We need to access the progress value for sorting, which MilestoneIdentifier doesn't have directly.
            // Let's define progress on MilestoneIdentifier temporarily for sorting here or sort by rawValue if it makes sense.
            // A better way: define progress on MilestoneIdentifier itself for reliable sorting.
            // Or, ensure MilestoneIdentifier.allCases returns them in the desired visual order of progression (04, 25, 50, 75, 100)
            // If not, we'll need to sort MilestoneIdentifier.allCases by their intended progress.
            // For now, assuming .allCases is already in the correct visual order of progression (04, 25, 50, 75, 100)
            // If MilestoneIdentifier rawValues were "0.04", "0.25" etc., we could sort by rawValue.
            // Given the current structure, we map then sort the Milestone array by its computed progress.
            return true // Placeholder, will sort after map
        }
        .map { Milestone(identifier: $0, isReached: false) }
        .sorted { $0.progress < $1.progress } // Sort the resulting [Milestone] array by their progress
    
    // DailyQuestDisplayInfo is defined inside ContentView for namespacing
    struct DailyQuestDisplayInfo {
        let id = "dailySlotSpinQuest"
        var title: String = "Daily Quest"
        var description: String = "Spin the Slot Machine 3 times."
        var progressText: String
        var rewardAmount: Int = 250
        var isCompleted: Bool
        var canClaim: Bool
        var cooldownActive: Bool
        var timeRemainingForNextQuestFormatted: String?
        var nextQuestAvailableDate: Date
    }
    
    static func handleDeepLink(_ url: URL) {
        print(" Handle deep link called with: \(url.absoluteString)")
        guard let deepLink = DeepLink(url: url) else {
            print(" Could not create DeepLink from URL")
            return
        }
        
        switch deepLink {
        case .legendaryCarPopup:
            print(" Posting notification for legendary car popup")
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowLegendaryCarPopup"),
                    object: nil
                )
            }
        }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [.white, Color(.systemGray5)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()

                        VStack(spacing: viewSize == .compact ? 15 : 25) {
                            // Top logo section
                            VStack(spacing: -20) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(
                                            .angularGradient(
                                                colors: [.blue, .purple, .red, .orange, .yellow, .blue],
                                                center: .center,
                                                startAngle: .degrees(45),
                                                endAngle: .degrees(405)
                                            )
                                        )
                                        .blur(radius: 15)
                                        .opacity(0.4)
                                        .frame(height: 170)
                                        .scaleEffect(1.01)
                                        .offset(y: 30)
                                    
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.white.opacity(1))
                                        .frame(height: 170)
                                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                                        .scaleEffect(0.99)
                                        .offset(y: 30)

                                    VStack {
                                        HStack {
                                            Spacer()
                                            Image("season_1")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 120)
                                                .offset(y: 40)
                                                .offset(x: -UIScreen.main.bounds.width/3.3)
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
                                                    material.emission.intensity = 0.45
                                                    material.specular.contents = UIColor.white
                                                    material.shininess = 0.8
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
                                                Text("0,0001%")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 4)
                                                    .background(
                                                        Capsule()
                                                            .fill(
                                                                LinearGradient(
                                                                    colors: [Color(hex: "FFB800"), Color(hex: "FF8A00")],
                                                                    startPoint: .leading,
                                                                    endPoint: .trailing
                                                                )
                                                            )
                                                            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                                                    )
                                                    .overlay(
                                                        Capsule()
                                                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5)
                                                    )
                                                    .padding(.bottom, -15)
                                            }
                                            .zIndex(3)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.top, 10)
                            
                            Spacer().frame(height: 15)

                            VStack(spacing: viewSize == .compact ? 15 : 25) {
                                // Boosters section
                                ZStack {
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(
                                            .angularGradient(
                                                colors: [.blue, .purple, .red, .orange, .yellow, .blue],
                                                center: .center,
                                                startAngle: .degrees(45),
                                                endAngle: .degrees(405)
                                            )
                                        )
                                        .blur(radius: 15)
                                        .opacity(0.25)
                                        .frame(height: viewSize == .compact ? 320 : 420)
                                        .scaleEffect(1.01)
                                    
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.white.opacity(1))
                                        .frame(height: viewSize == .compact ? 320 : 420)
                                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                                        .scaleEffect(0.99)

                                    VStack {
                                        Spacer()
                                        HStack(spacing: viewSize == .compact ? -20 : -10) {
                                            // First booster
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
                                                        Rectangle()
                                                            .fill(
                                                                LinearGradient(
                                                                    gradient: Gradient(colors: [.clear, .white.opacity(0.05), .white.opacity(0.3), .white.opacity(0.05), .clear]),
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                )
                                                            )
                                                            .frame(width: 120)
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

                                            // Second booster
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
                                                        Rectangle()
                                                            .fill(
                                                                LinearGradient(
                                                                    gradient: Gradient(colors: [.clear, .white.opacity(0.05), .white.opacity(0.3), .white.opacity(0.05), .clear]),
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                )
                                                            )
                                                            .frame(width: 120)
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
                                        
                                        // Booster Info and Daily Quest Capsules
                                        HStack(spacing: 8) { 
                                            styledCapsuleBackground {
                                                boosterStatusContentView()
                                            }
                                            .frame(maxWidth: UIScreen.main.bounds.width * 0.58) 
                                            
                                            styledCapsuleBackground {
                                                dailyQuestButtonView()
                                            }
                                            .frame(width: 60) // Fixed width for quest button capsule
                                        }
                                        .padding(.horizontal) // Add horizontal padding to the HStack containing the capsules
                                        .offset(y: 0)
                                        .zIndex(1)
                                    }
                                    .padding(.top, 10)
                                }
                                .padding(.horizontal, horizontalPadding)
                                .padding(.vertical, viewSize == .compact ? 8 : 15)
                                .onAppear {
                                    withAnimation(Animation.linear(duration: 7.0).repeatForever(autoreverses: true)) {
                                        booster1GlareOffset = 250
                                    }
                                    withAnimation(Animation.linear(duration: 7.0).delay(0.7).repeatForever(autoreverses: true)) {
                                        booster2GlareOffset = 250
                                    }
                                }
 
                                // Collection and Shop buttons
                                HStack(spacing: 15) {
                                    NavigationLink(destination: CollectionView(collectionManager: collectionManager).navigationBarTitleDisplayMode(.inline)) {
                                        buttonView(icon: "", text: "", colors: [.gray.opacity(0.3)], textColor: .gray)
                                            .overlay(
                                                VStack(spacing: 4) {
                                                    Image("collection")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 35, height: 35)
                                                    Text("Collection")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(.gray)
                                                }
                                            )
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
                                                        .scaleEffect(coinScale)
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
                                .padding(.vertical, viewSize == .compact ? 4 : 8)

                                progressBarSection
                                    .padding(.bottom, 15)
                            }
                        }
                        .frame(maxWidth: viewSize == .compact ? .infinity : min(geometry.size.width * 0.8, 800))
                        .frame(maxWidth: .infinity)
                        .animation(hasAppeared ? .default : nil, value: hasAppeared)
                        
                        if showMilestoneRewardPopup, let milestonePopupInfo = currentMilestoneForPopup {
                            MilestoneRewardPopup(
                                milestoneInfo: milestonePopupInfo,
                                onClaim: {
                                    collectionManager.claimMilestone(milestonePopupInfo.id)
                                    updateLocalMilestoneStates() // CALLING METHOD
                                    showMilestoneRewardPopup = false
                                    currentMilestoneForPopup = nil
                                    AudioManager.shared.playPurchaseSound()
                                },
                                onClose: {
                                    showMilestoneRewardPopup = false
                                    currentMilestoneForPopup = nil
                                }
                            )
                            .zIndex(10)
                        }
                        if showDailyQuestPopup, let questInfo = currentDailyQuestDisplayInfo {
                            DailyQuestPopupView(
                                questInfo: questInfo,
                                onClaim: {
                                    claimDailyQuestReward() // CALLING METHOD
                                    showDailyQuestPopup = false
                                    currentDailyQuestDisplayInfo = nil
                                },
                                onClose: {
                                    showDailyQuestPopup = false
                                    currentDailyQuestDisplayInfo = nil
                                }
                            )
                            .zIndex(11)
                        }
                    }
                }
            }
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
        }
        .task {
            if await AppUpdateChecker.shared.checkForUpdate() {
                showUpdateAlert = true
            }
        }
        .alert(AppUpdateChecker.shared.updateRequired ? "Mise à jour requise" : "Mise à jour disponible", isPresented: $showUpdateAlert) {
            Button("Mettre à jour") {
                AppUpdateChecker.shared.openAppStore()
            }
            if !AppUpdateChecker.shared.updateRequired {
                Button("Plus tard", role: .cancel) { }
            }
        } message: {
            Text(AppUpdateChecker.shared.updateRequired ?
                "Une mise à jour importante est requise pour continuer à utiliser l'application." :
                "Une nouvelle version de Pocket Car est disponible sur l'App Store.")
        }
        .background(
            NavigationLink(
                destination: ShopView(collectionManager: collectionManager, storeManager: StoreManager.shared),
                isActive: $navigateToBooster
            ) { EmptyView() }
        )
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowLegendaryCarPopup"))) { _ in
            print(" Received notification to show popup")
            DispatchQueue.main.async {
                self.showExclusiveCarInfo = true
                print(" Set showExclusiveCarInfo to true")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .milestoneClaimed)) { _ in
            updateLocalMilestoneStates() // CALLING METHOD
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                hasAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startBreathingAnimation() // CALLING METHOD
            }
            updateLocalMilestoneStates() // CALLING METHOD
            updateDailyQuestStatus()     // CALLING METHOD
        }
        .onChange(of: dailyQuestSpinsCount) { _, _ in
            updateDailyQuestStatus()     // CALLING METHOD
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            updateDailyQuestStatus()     // CALLING METHOD
        }
    }
    
    // MARK: - Subviews
    
    var progressBarSection: some View {
        NavigationLink(destination: CollectionProgressView(collectionManager: collectionManager)) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Collection progress")
                        .font(.system(size: viewSize == .compact ? 12 : 16))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(collectionManager.cards.count)/250")
                        .font(.system(size: viewSize == .compact ? 12 : 16))
                        .foregroundColor(.gray)
                }
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    ZStack {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.yellow, Color.orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        GeometryReader { geometry in
                            let width = geometry.size.width
                            let baseProgress = Double(collectionManager.cards.count) / 250.0
                            let totalProgress = baseProgress + (breathingProgress * 0.05)
                            
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .white.opacity(0.1), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .mask(
                                    HStack(spacing: 0) {
                                        ForEach(0..<2) { i in
                                            Capsule()
                                                .fill(Color.white)
                                                .frame(width: width * 1.5)
                                                .offset(x: -width/2 + (waveOffset + Double(i)) * width)
                                        }
                                    }
                                )
                        }
                    }
                    .frame(width: calculateProgressWidth(), height: 8) // CALLING METHOD
                    .animation(.spring(dampingFraction: 0.8), value: breathingProgress)
                    .onAppear {
                        // startBreathingAnimation() is called in main onAppear
                        withAnimation(
                            .linear(duration: 2)
                            .repeatForever(autoreverses: false)
                        ) {
                            waveOffset = 1
                        }
                    }
                    milestoneMarkersView() // CALLING METHOD
                }
                .frame(height: 35)
            }
            .padding(15)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .glow(
                            fill: .angularGradient(
                                colors: [.blue, .purple, .red, .orange, .yellow, .blue],
                                center: .center,
                                startAngle: .degrees(45),
                                endAngle: .degrees(405)
                            ),
                            lineWidth: 2.0,
                            blurRadius: 4.0
                        )
                        .opacity(0.6)
                    
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

    @ViewBuilder
    private func milestoneMarkersView() -> some View {
        ForEach($milestones) { $milestone_local in
            let milestoneID = milestone_local.identifier

            Button(action: {
                // ... action du bouton reste inchangée ...
                let progressPercentage = Double(collectionManager.cards.count) / 250.0 * 100.0
                let milestoneTargetProgressDecimal = milestone_local.progress // Use computed progress
                let isReachable = (Double(collectionManager.cards.count) / 250.0) >= milestoneTargetProgressDecimal

                if isReachable && !collectionManager.claimedMilestones.contains(milestoneID) {
                    var rewardDesc = ""
                    var rewardCardForPopup: BoosterCard? = nil
                    var rewardBoostersForPopup: Int? = nil
                    
                    if let card = milestoneID.rewardCard {
                        rewardDesc = "You've unlocked the \(card.name)!"
                        rewardCardForPopup = card
                    } else if milestoneID.rewardBoosters > 0 {
                        rewardDesc = "You've earned \(milestoneID.rewardBoosters) boosters!"
                        rewardBoostersForPopup = milestoneID.rewardBoosters
                    } else if milestoneID.rewardCoins > 0 {
                         rewardDesc = "You've earned \(milestoneID.rewardCoins) coins!"
                    } else {
                        rewardDesc = "You've reached a new milestone!"
                    }

                    currentMilestoneForPopup = CollectionProgressView.MilestoneToDisplay(
                        id: milestoneID,
                        title: "Reward Unlocked!",
                        rewardDescription: rewardDesc,
                        iconName: milestone_local.icon, // Use computed icon
                        rewardCard: rewardCardForPopup,
                        rewardBoosters: rewardBoostersForPopup
                    )
                    showMilestoneRewardPopup = true
                    HapticManager.shared.impact(style: .medium)
                } else if collectionManager.claimedMilestones.contains(milestoneID) {
                    print("Milestone \(milestoneID.rawValue) already claimed.")
                    HapticManager.shared.impact(style: .light)
                } else {
                    print("Milestone \(milestoneID.rawValue) not yet reached. Current progress: \(Double(collectionManager.cards.count) / 250.0), Target: \(milestoneTargetProgressDecimal)")
                    HapticManager.shared.impact(style: .soft)
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.1), radius: 2)
                    
                    if milestoneID == .progress04 { // Assuming .progress04 uses your custom PNG
                        Image(milestone_local.icon) // This is your "nom_de_votre_image_png"
                            .resizable() // Permet à l'image d'être redimensionnée
                            .scaledToFill() // S'assure que l'image remplit le cadre, peut couper des parties si le ratio ne correspond pas
                                            // ou .scaledToFit() si vous voulez voir toute l'image et accepter des espaces vides.
                                            // Pour "étirer au max" sans déformer mais en remplissant, .scaledToFill() est souvent ce qu'on veut dans un cercle.
                            .frame(width: 14, height: 14) // Le cadre dans lequel l'image doit s'adapter
                            .clipShape(Circle()) // Important si .scaledToFill() est utilisé et que l'image n'est pas carrée
                                                 // pour qu'elle ne dépasse pas le cercle implicite de l'icône.
                            .opacity(milestone_local.isReached ? 1.0 : 0.5)
                    } else { // For other icons (SF Symbols or other assets)
                        Image(milestone_local.icon)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(milestone_local.isReached ? (milestoneID.rewardCard != nil || milestoneID.rewardBoosters > 0 ? .orange : .yellow) : .gray)
                            .frame(width: 14, height: 14)
                            .opacity(milestone_local.isReached ? 1.0 : 0.5)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .leading, endPoint: .trailing), lineWidth: 1.5)
                )
                .overlay(
                    Circle()
                        .stroke(LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .leading, endPoint: .trailing), lineWidth: milestone_local.isReached ? 2 : 0)
                        .blur(radius: 2)
                        .opacity(milestone_local.isReached ? 0.7 : 0)
                )
                .scaleEffect(milestone_local.isReached && !collectionManager.claimedMilestones.contains(milestoneID) ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: milestone_local.isReached || collectionManager.claimedMilestones.contains(milestoneID))
                .overlay(
                    Group {
                        if collectionManager.claimedMilestones.contains(milestoneID) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 10))
                                .padding(1)
                                .background(Color.white.clipShape(Circle()))
                                .offset(x: 8, y: -8)
                        }
                    }
                )
            }
            .position(x: UIScreen.main.bounds.width * 0.7 * CGFloat(milestone_local.progress), y: 12)
            .onChange(of: collectionManager.cards.count) { _, newCount in
                let currentProgress = Double(newCount) / 250.0
                if !milestone_local.isReached && currentProgress >= milestone_local.progress {
                    milestone_local.isReached = true
                }
            }
        }
    }

    // MARK: - Helper Functions for View Logic

    private func calculateProgressWidth() -> CGFloat {
        let maxWidth = UIScreen.main.bounds.width * 0.7
        let baseProgress = Double(collectionManager.cards.count) / 250.0
        let totalProgress = baseProgress + (breathingProgress * 0.05)
        return maxWidth * totalProgress
    }

    private func buttonView(icon: String, text: String, colors: [Color], textColor: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .glow(
                    fill: .angularGradient(
                        colors: [.blue, .purple, .red, .orange, .yellow, .blue],
                        center: .center,
                        startAngle: .degrees(45),
                        endAngle: .degrees(405)
                    ),
                    lineWidth: 2.0,
                    blurRadius: 4.0
                )
                .opacity(0.6)
            
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
            
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
        }
    }
    
    @ViewBuilder
    private func styledCapsuleBackground<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                ZStack {
                    Capsule()
                        .glow(
                            fill: .angularGradient(
                                colors: [.blue, .purple, .red, .orange, .yellow, .blue],
                                center: .center,
                                startAngle: .degrees(45),
                                endAngle: .degrees(405)
                            ),
                            lineWidth: 2.0,
                            blurRadius: 4.0
                        )
                        .opacity(0.6)
                    
                    Capsule()
                        .fill(Color.white)
                }
            )
    }

    @ViewBuilder
    private func boosterStatusContentView() -> some View {
        HStack {
            if StoreManager.shared.boosters > 0 {
                Image("gift")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .modifier(ShakeEffect(animatableData: Double(shakeOffset)))
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                        ) {
                            shakeOffset = 1
                        }
                    }
                HStack(spacing: 4) {
                    Text("\(StoreManager.shared.boosters)")
                        .foregroundColor(.gray)
                    Text("booster")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            } else if StoreManager.shared.nextFreeBoosterDate != nil {
                BoosterTimerView(storeManager: StoreManager.shared)
            } else {
                Image(systemName: "hand.tap")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
                Text("Click booster")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            }
        }
    }

    @ViewBuilder
    private func dailyQuestButtonView() -> some View {
        let questReadyToClaim = (currentDailyQuestDisplayInfo?.canClaim ?? false) && !(currentDailyQuestDisplayInfo?.cooldownActive ?? true)
        let questInProgress = !(currentDailyQuestDisplayInfo?.isCompleted ?? true) && !(currentDailyQuestDisplayInfo?.cooldownActive ?? true) && (currentDailyQuestDisplayInfo != nil)

        Button(action: {
            updateDailyQuestStatus() // CALLING METHOD
            showDailyQuestPopup = true
            HapticManager.shared.impact(style: .medium)
        }) {
            HStack {
                ZStack {
                    Image(systemName: "list.star")
                        .font(.system(size: 18))
                        .foregroundColor(questReadyToClaim ? .yellow : (questInProgress ? .blue : .gray))
                    
                    if questReadyToClaim {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 10, y: -10)
                            .opacity(isAnimating ? 1 : 0.5)
                            .animation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: isAnimating)
                    }
                }
            }
        }
        .onAppear {
            if questReadyToClaim { isAnimating = true }
        }
        .onChange(of: currentDailyQuestDisplayInfo?.canClaim) { _, newValue in
            if newValue == true && currentDailyQuestDisplayInfo?.cooldownActive == false {
                isAnimating = true
            } else {
                isAnimating = false
            }
        }
    }

    private func updateDailyQuestStatus() {
        let currentTime = Date()
        let nextQuestDate = Date(timeIntervalSince1970: nextDailyQuestTime)
        let requiredSpins = 3
        var cooldownIsActive = false
        var timeRemainingString: String? = nil

        if currentTime < nextQuestDate && isCurrentDailyQuestRewardClaimed {
            cooldownIsActive = true
            let remaining = nextQuestDate.timeIntervalSince(currentTime)
            timeRemainingString = formatTimeInterval(remaining) // CALLING METHOD
        } else if currentTime >= nextQuestDate && isCurrentDailyQuestRewardClaimed {
            isCurrentDailyQuestRewardClaimed = false
            dailyQuestSpinsCount = 0
        }

        let completed = dailyQuestSpinsCount >= requiredSpins
        let canBeClaimed = completed && !isCurrentDailyQuestRewardClaimed && !cooldownIsActive

        currentDailyQuestDisplayInfo = DailyQuestDisplayInfo(
            progressText: "\(min(dailyQuestSpinsCount, requiredSpins))/\(requiredSpins) spins",
            isCompleted: completed,
            canClaim: canBeClaimed,
            cooldownActive: cooldownIsActive,
            timeRemainingForNextQuestFormatted: timeRemainingString,
            nextQuestAvailableDate: nextQuestDate
        )
    }

    private func claimDailyQuestReward() {
        guard let info = currentDailyQuestDisplayInfo, info.canClaim else { return }

        collectionManager.coins += info.rewardAmount
        AudioManager.shared.playPurchaseSound()
        HapticManager.shared.impact(style: .heavy)

        isCurrentDailyQuestRewardClaimed = true
        dailyQuestSpinsCount = 0
        let twelveHours: TimeInterval = 12 * 60 * 60
        nextDailyQuestTime = Date().timeIntervalSince1970 + twelveHours
        
        updateDailyQuestStatus() // CALLING METHOD
        
        NotificationCenter.default.post(name: .coinsDidUpdate, object: nil)
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? ""
    }

    private func startBreathingAnimation() {
        // Guard against starting multiple animations if isAnimating is already true
        // or if hasAppeared is false to prevent animation before view is ready.
        guard !isAnimating, hasAppeared else { return }
        
        isAnimating = true
        let animation = Animation
            .easeInOut(duration: 2)
            .repeatForever(autoreverses: true)
        
        withAnimation(animation) {
            breathingProgress = 1
        }
    }

    private func updateLocalMilestoneStates() {
        let currentCardCount = collectionManager.cards.count
        let totalCardsForProgress = 250.0
        
        for i in milestones.indices {
            let milestoneTargetProgress = milestones[i].progress
            if Double(currentCardCount) / totalCardsForProgress >= milestoneTargetProgress {
                if !milestones[i].isReached {
                    milestones[i].isReached = true
                }
            } else {
                 if milestones[i].isReached {
                    milestones[i].isReached = false
                 }
            }
        }
    }
} // FIN DE LA STRUCT ContentView

// DailyQuestPopupView est une struct SÉPARÉE
struct DailyQuestPopupView: View {
    let questInfo: ContentView.DailyQuestDisplayInfo
    var onClaim: () -> Void
    var onClose: () -> Void
    
    @State private var isAnimatingGlow = false
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onClose() }
            
            VStack(spacing: 0) {
                HStack {
                    Text(questInfo.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: "333333"))
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                }
                .padding()
                .background(Color.white.opacity(0.8))
                
                Divider()
                
                VStack(spacing: 15) {
                    Image("Slot") // Assuming "Slot.png" is in your assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80) // Adjusted size slightly for potentially more detailed image
                        .padding(.top)
                    
                    Text(questInfo.description)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "555555"))
                        .multilineTextAlignment(.center)
                    
                    Text(questInfo.cooldownActive && questInfo.timeRemainingForNextQuestFormatted != nil ? "Next quest in: \(questInfo.timeRemainingForNextQuestFormatted!)" : questInfo.progressText)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(questInfo.isCompleted && !questInfo.cooldownActive ? .green : .orange)
                    
                    if questInfo.canClaim {
                        Text("Reward: \(questInfo.rewardAmount) coins")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "666666"))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if questInfo.canClaim {
                            onClaim()
                        } else {
                            onClose()
                        }
                    }) {
                        Text(questInfo.canClaim ? "Claim Reward!" : (questInfo.cooldownActive ? "Come Back Later" : "Awesome!"))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 30)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: questInfo.canClaim ? [Color.green, Color.blue] : [Color.orange, Color.pink]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                            .shadow(color: (questInfo.canClaim ? Color.blue : Color.pink).opacity(0.4), radius: 5, y: 3)
                    }
                    // The button's action already handles different states for closing.
                    // .disabled(!questInfo.canClaim && !questInfo.cooldownActive && !questInfo.isCompleted)
                    // .opacity( (questInfo.isCompleted && !questInfo.canClaim && !questInfo.cooldownActive) ? 0.7 : 1.0)
                    
                }
                .padding()
            }
            .frame(width: UIScreen.main.bounds.width * 0.85, height: UIScreen.main.bounds.height * 0.45)
            .background(Color.white)
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.2), radius: 20)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple.opacity(0.7), .blue.opacity(0.7), .green.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isAnimatingGlow ? 4 : 2
                    )
                    .blur(radius: isAnimatingGlow ? 3 : 0)
                    .opacity(isAnimatingGlow ? 1 : 0.6)
            )
            .scaleEffect(showContent ? 1 : 0.95)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .onAppear {
                AudioManager.shared.playSound(named: "popup_appear.mp3")
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1)) {
                    showContent = true
                }
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.2)) {
                    isAnimatingGlow = true
                }
            }
        }
        .zIndex(100)
    }
} // FIN DE DailyQuestPopupView

// ContentView_Previews est une struct SÉPARÉE
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
