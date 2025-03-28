import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var rotation = 0.0
    @State private var progress = 0.0
    
    var body: some View {
        if isActive {
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
                
                Text("Checking the turbos...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
            .onAppear {
                // Initial animation
                withAnimation(.easeIn(duration: 1.2)) {
                    self.size = 0.9
                    self.opacity = 1.0
                }
                
                // Progress and rotation animation
                withAnimation(.line
                              ar(duration: 6).repeatCount(1, autoreverses: false)) {
                    self.progress = 1.0
                    self.rotation = 360
                }
                
                // Transition to main view after 6 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
