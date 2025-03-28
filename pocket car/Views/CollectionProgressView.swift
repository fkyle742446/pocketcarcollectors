import SwiftUI

struct CollectionProgressView: View {
    let progress: Double
    let rarityCount: [CardRarity: Int]
    let totalCount: Int
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                    .overlay(
                        AngularGradient(
                            colors: [.blue, .purple, .red, .orange, .yellow, .blue],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        )
                        .mask(
                            Circle()
                                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                        )
                    )
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: progress)

                VStack {
                    Text(String(format: "%.0f%%", min(self.progress, 1.0)*100.0))
                        .font(.largeTitle)
                        .bold()
                    Text("\(totalCount) cards")
                        .font(.caption)
                }
            }
            .frame(width: 150, height: 150)
        }
    }
}

struct ProgressCard: View {
    let title: String
    let subtitle: String?
    let count: Int
    let total: Int
    let colors: [Color]
    
    var percentage: Double {
        Double(count) / Double(total) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) { 
            HStack {
                VStack(alignment: .leading, spacing: 2) { 
                    Text(title)
                        .font(.system(size: 16, weight: .medium)) 
                        .foregroundColor(.gray)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .regular)) 
                            .foregroundColor(.gray.opacity(0.8))
                    }
                }
                
                Spacer()
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.system(size: 14, weight: .medium)) 
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("\(count)/\(total)")
                    .font(.system(size: 12)) 
                    .foregroundColor(.gray)
                Spacer()
            }
            
            ProgressView(value: Double(count), total: Double(total))
                .frame(height: 6) 
                .tint(
                    LinearGradient(
                        colors: colors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .background(Color.white)
        }
        .padding(12) 
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16) 
                    .fill(Color.white)
            }
        )
    }
}

#Preview {
    NavigationView {
        CollectionProgressView(progress: 0.5, rarityCount: [:], totalCount: 100)
    }
}
