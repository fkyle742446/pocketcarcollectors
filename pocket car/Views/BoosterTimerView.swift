import SwiftUI
import Foundation

struct BoosterTimerView: View {
    @StateObject private var storeManager = StoreManager.shared
    @State private var timeRemaining: TimeInterval?
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            if storeManager.remainingFreeBoosters > 0 {
                Text("\(storeManager.remainingFreeBoosters) boosters gratuits restants")
                    .foregroundColor(.green)
            } else if let timeRemaining = timeRemaining {
                Text("Prochain booster dans: \(formatTime(timeRemaining))")
                    .foregroundColor(storeManager.hasDetectedTimeManipulation ? .red : .primary)
            } else {
                Text("Booster disponible!")
                    .foregroundColor(.green)
            }
            
            if storeManager.hasDetectedTimeManipulation {
                Text("Manipulation du temps détectée !")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .onReceive(timer) { _ in
            timeRemaining = storeManager.timeUntilNextBooster()
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
