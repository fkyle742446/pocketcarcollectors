import SwiftUI

struct BoosterSection: View {
    let viewSize: ViewSize
    @ObservedObject var collectionManager: CollectionManager
    @Binding var showLockedBoosterInfo: Bool
    @Binding var glowRotationAngle: Double
    @State private var booster1GlareOffset: CGFloat = -200
    @State private var booster2GlareOffset: CGFloat = -200
    @State private var booster1Rotation: Double = -5
    @State private var booster2Rotation: Double = 5
    @State private var shakeOffset: CGFloat = 0
    
    private var boosterHeight: CGFloat {
        viewSize == .compact ? 240 : 300
    }
    
    var body: some View {
        // Existing booster section implementation...
    }
}