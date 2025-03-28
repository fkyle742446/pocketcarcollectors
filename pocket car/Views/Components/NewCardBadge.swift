import SwiftUI

struct NewCardBadge: View {
    var body: some View {
        Text("NEW")
            .font(.system(size: 8, weight: .black))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .rotationEffect(.degrees(0))
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}