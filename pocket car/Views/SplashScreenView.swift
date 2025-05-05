import SwiftUI

struct SplashScreenView: View {
    @StateObject private var preloadManager = PreloadManager()
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var rotation = 0.0
    @State private var progress = 0.0
    @State private var currentTextIndex = 0
    @State private var contentView: ContentView? = nil
    @State private var fadeOut = false
    
    let loadingTexts = [
        "Checking the turbos...",
        "Warming up the engines...",
        "Polishing the bodywork...",
        "Adjusting suspension...",
        "Filling up the tank...",
        "Starting the V12...",
        "Ready to collect!"
    ]
    
    var body: some View {
        ZStack {
            if isActive && preloadManager.isLoaded {
                if let loadedContentView = contentView {
                    loadedContentView
                } else {
                    ContentView()
                }
            } else {
                VStack {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 150)
                        .scaleEffect(size)
                        .opacity(opacity)
                    
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
                .opacity(fadeOut ? 0 : 1)
                .animation(.easeInOut(duration: 0.6), value: fadeOut)
                .onAppear {
                    // Start splash screen music
                    AudioManager.shared.playSplashMusic()
                    
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 0.9
                        self.opacity = 1.0
                    }
                    
                    withAnimation(.linear(duration: 6).repeatCount(1, autoreverses: false)) {
                        self.progress = 1.0
                        self.rotation = 360
                    }
                    
                    let textInterval = 6.0 / Double(loadingTexts.count)
                    for index in 0..<loadingTexts.count {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * textInterval) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentTextIndex = index
                            }
                        }
                    }
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        let preloadedContentView = ContentView()
                        
                        preloadManager.preloadResources {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                                withAnimation(.easeOut(duration: 0.6)) {
                                    self.fadeOut = true
                                }
                                
                                // Transition to ContentView after fade out
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    AudioManager.shared.stopSplashMusic {
                                        AudioManager.shared.startBackgroundMusic()
                                    }
                                    
                                    self.contentView = preloadedContentView
                                    self.isActive = true
                                }
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
