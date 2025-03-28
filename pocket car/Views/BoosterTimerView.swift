import SwiftUI
import Foundation

class BoosterTimer: ObservableObject {
    static let shared = BoosterTimer()
    
    @AppStorage("freeBoosters") var freeBoosters = 4 {
        willSet {
            objectWillChange.send()
        }
    }
    
    @AppStorage("nextBoosterTime") var nextBoosterTime = Date().timeIntervalSinceReferenceDate {
        willSet {
            objectWillChange.send()
        }
    }
    
    @Published private(set) var timeRemaining: TimeInterval = 0
    private let cooldownDuration: TimeInterval = 6 * 3600 // 6 heures
    
    private init() {
        updateTimer()
    }
    
    func updateTimer() {
        let now = Date().timeIntervalSinceReferenceDate
        timeRemaining = max(0, nextBoosterTime - now)
        objectWillChange.send()
    }
    
    func canOpenBooster() -> Bool {
        if freeBoosters > 0 {
            return true
        }
        return Date().timeIntervalSinceReferenceDate >= nextBoosterTime
    }
    
    func useBooster() {
        if freeBoosters > 0 {
            freeBoosters -= 1
            if freeBoosters == 0 {
                startNewTimer()
            }
        } else if canOpenBooster() {
            startNewTimer()
        }
    }
    
    private func startNewTimer() {
        nextBoosterTime = Date().timeIntervalSinceReferenceDate + cooldownDuration
        updateTimer()
    }
}

struct BoosterTimerView: View {
    @ObservedObject private var boosterTimer = BoosterTimer.shared
    @StateObject private var storeManager = StoreManager.shared
    @State private var showingPointsAlert = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            if boosterTimer.freeBoosters > 0 {
                boosterCountView
            } else if boosterTimer.timeRemaining > 0 {
                timerView
            } else {
                availableView
            }
        }
        .frame(height: 30) // Fixed height to prevent layout shifts
        .alert("Use Points", isPresented: $showingPointsAlert) {
            let hoursNeeded = Int(ceil(boosterTimer.timeRemaining / 3600))
            
            Button("Use \(hoursNeeded) Points") {
                if storeManager.usePoints(amount: hoursNeeded) {
                    boosterTimer.useBooster()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let hoursNeeded = Int(ceil(boosterTimer.timeRemaining / 3600))
            Text("You need \(hoursNeeded) points to skip this timer.\nYou have \(storeManager.availablePoints) points available.")
        }
        .onAppear {
            boosterTimer.updateTimer()
        }
        .onReceive(timer) { _ in
            boosterTimer.updateTimer()
        }
    }
    
    private var boosterCountView: some View {
        Text("\(boosterTimer.freeBoosters) boosters gratuits restants")
            .foregroundColor(.green)
            .bold()
            .transition(.opacity)
    }
    
    private var timerView: some View {
        Text("Prochain booster dans : \(formatTime(boosterTimer.timeRemaining))")
            .foregroundColor(.gray)
            .onTapGesture {
                showingPointsAlert = true
            }
            .transition(.opacity)
    }
    
    private var availableView: some View {
        Text("Booster disponible !")
            .foregroundColor(.green)
            .bold()
            .transition(.opacity)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
