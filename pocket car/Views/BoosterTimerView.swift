import SwiftUI
import Combine

struct BoosterTimerView: View {
    @ObservedObject private var storeManager: StoreManager
    @State private var timeRemaining: TimeInterval?
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init() {
        self._storeManager = ObservedObject(wrappedValue: StoreManager.shared)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            if let freeBoosters = storeManager.remainingFreeBoosters, freeBoosters > 0 {
                Text("\(freeBoosters) boosters gratuits restants")
                    .foregroundColor(.green)
            } else if let remaining = timeRemaining {
                Text("Prochain booster dans: \(formatTime(remaining))")
                    .foregroundColor(storeManager.hasDetectedTimeChange ? .red : .primary)
            } else {
                Text("Booster disponible!")
                    .foregroundColor(.green)
            }
            
            if storeManager.hasDetectedTimeChange {
                Text("Timer réinitialisé")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            updateTimeRemaining()
        }
        .onReceive(timer) { _ in
            updateTimeRemaining()
        }
    }
    
    private func updateTimeRemaining() {
        if let nextTime = storeManager.timeUntilNextBooster() {
            self.timeRemaining = nextTime
        } else {
            self.timeRemaining = nil
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
