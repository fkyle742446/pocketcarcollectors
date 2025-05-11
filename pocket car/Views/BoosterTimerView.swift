import SwiftUI

struct BoosterTimerView: View {
    @ObservedObject var storeManager: StoreManager
    @State private var timeString: String = ""
    
    var body: some View {
        HStack(spacing: 8) {
            if storeManager.boosters > 0 {
                Image(systemName: "gift.fill")
                    .foregroundColor(.gray)
                Text("\(storeManager.boosters) free boosters remaining")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            } else if let _ = storeManager.nextFreeBoosterDate {
                Image("clock")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("Next booster in \(timeString)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            updateTimeString()
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                updateTimeString()
            }
        }
    }
    
    private func updateTimeString() {
        guard let nextDate = storeManager.nextFreeBoosterDate else { return }
        
        let remaining = nextDate.timeIntervalSinceNow
        if remaining > 0 {
            let hours = Int(remaining) / 3600
            let minutes = Int(remaining) / 60 % 60
            let seconds = Int(remaining) % 60
            
            timeString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            storeManager.validateBoosterTimer()
            timeString = "00:00:00" 
            // After validateBoosterTimer, the @Published nextFreeBoosterDate
            // in StoreManager might update. This should trigger a view update, and
            // updateTimeString will be called again by the system or the timer.
            // If validateBoosterTimer itself determines a new timer should start,
            // it will update nextFreeBoosterDate which then gets reflected here.
        }
    }
}

// Preview pour tester
struct BoosterTimerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.1)
                .ignoresSafeArea()
            BoosterTimerView(storeManager: StoreManager.shared)
                .padding()
        }
    }
}
