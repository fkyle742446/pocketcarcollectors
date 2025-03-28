import SwiftUI

struct SplashScreenView: View {
    @StateObject private var preloadManager = PreloadManager()
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var rotation = 0.0
    @State private var progress = 0.0
    @State private var currentTextIndex = 0
    
    let loadingTexts = [
        "Checking the turbos...",
        "Warming up the engines...",
        "Polishing the bodywork...",
        "Adjusting suspension...",
        "Filling up the tank...",
        "Testing the nitro...",
        "Ready to race!"
    ]
    
    var body: some View {
        ZStack {
            if isActive && preloadManager.isLoaded {
                ContentView()
            } else {
                VStack {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 150)
                        .scaleEffect(size)
                        .opacity(opacity)
                    
                    // Progress circle
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 3)
                            .opacity(0.3)
                            .foregroundColor(Color.gray)
                            .frame(width: 40, height: 40)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                LinearGradient(
                                    colors: [.pink, .purple, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 40, height: 40)
                            .rotationEffect(Angle(degrees: rotation))
                    }
                    .padding(.top, 20)
                    
                    Text(loadingTexts[currentTextIndex])
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .transition(.opacity)
                        .id(currentTextIndex)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .onAppear {
                    // Initial animation
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 0.9
                        self.opacity = 1.0
                    }
                    
                    // Progress and rotation animation
                    withAnimation(.linear(duration: 6).repeatCount(1, autoreverses: false)) {
                        self.progress = 1.0
                        self.rotation = 360
                    }
                    
                    // Text animation
                    let textInterval = 6.0 / Double(loadingTexts.count)
                    for index in 0..<loadingTexts.count {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * textInterval) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentTextIndex = index
                            }
                        }
                    }
                    
                    // Start preloading resources
                    preloadManager.preloadResources {
                        // Only transition when both timer is done and resources are loaded
                        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                self.isActive = true
                            }
                        }
                    }
                }
            }
        }
        .transition(.opacity)
    }
}

#Preview {
    SplashScreenView()
}
