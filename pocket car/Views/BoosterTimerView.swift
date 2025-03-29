import SwiftUI

struct BoosterTimerView: View {
    @ObservedObject var storeManager = StoreManager.shared
    @State private var timeRemaining: String = ""
    
    var body: some View {
        HStack {
            if storeManager.boosters > 0 {
                Image(systemName: "gift.fill")
                    .foregroundColor(.gray)
                Text("\(storeManager.boosters) free boosters remaining")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            } else if let _ = storeManager.nextFreeBoosterDate {
                Image(systemName: "clock.fill")
                    .foregroundColor(.gray)
                Text("Next booster in \(timeRemaining)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            updateTimer()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            updateTimer()
        }
    }
    
    private func updateTimer() {
        guard let nextDate = storeManager.nextFreeBoosterDate else { return }
        
        let remaining = Int(nextDate.timeIntervalSince1970 - Date().timeIntervalSince1970)
        if remaining > 0 {
            let hours = remaining / 3600
            let minutes = (remaining % 3600) / 60
            let seconds = remaining % 60
            timeRemaining = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            storeManager.checkForFreeBooster()
        }
    }
}

// Preview pour tester
struct BoosterTimerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.1)
                .ignoresSafeArea()
            BoosterTimerView()
                .padding()
        }
    }
}
