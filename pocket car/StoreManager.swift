import SwiftUI
import Combine

class StoreManager: ObservableObject {
 static let shared = StoreManager()
 
 @Published var currentTimeString = "06h00"
 @Published var hoursNeeded = 6
 @Published var availablePoints = 0
 
 private let boosterInterval: TimeInterval = 6 * 60 * 60 // 6 heures
 private var timer: AnyCancellable?
 
 init() {
     setupInitialState()
     startTimer()
 }
 
 private func setupInitialState() {
     // Initialisation depuis UserDefaults
     availablePoints = UserDefaults.standard.integer(forKey: "points")
     
     if UserDefaults.standard.object(forKey: "lastBoosterTime") == nil {
         // Premier lancement
         UserDefaults.standard.set(4, forKey: "boosters") // 4 boosters initiaux
         UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastBoosterTime")
     }
 }
 
 private func startTimer() {
     timer = Timer.publish(every: 1, on: .main, in: .default)
         .autoconnect()
         .sink { [weak self] _ in
             self?.updateTimer()
         }
 }
 
 private func updateTimer() {
     let lastTime = UserDefaults.standard.double(forKey: "lastBoosterTime")
     let now = Date().timeIntervalSince1970
     let elapsed = now - lastTime
     
     if elapsed >= boosterInterval {
         // Ajouter des boosters
         let periods = Int(elapsed / boosterInterval)
         let newBoosters = UserDefaults.standard.integer(forKey: "boosters") + periods
         UserDefaults.standard.set(newBoosters, forKey: "boosters")
         
         currentTimeString = "06h00"
         hoursNeeded = 6
     } else {
         // Mettre à jour le timer
         let remaining = boosterInterval - elapsed
         let hours = Int(remaining) / 3600
         let minutes = (Int(remaining) % 3600) / 60
         currentTimeString = String(format: "%02dh%02d", hours, minutes)
         hoursNeeded = Int(ceil(remaining / 3600))
     }
 }
 
 func skipWaitingTime() {
     guard availablePoints >= hoursNeeded else { return }
     
     availablePoints -= hoursNeeded
     UserDefaults.standard.set(availablePoints, forKey: "points")
     
     // Réinitialiser le timer
     UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastBoosterTime")
     updateTimer()
 }
}

BoosterTimerView.swift
swift
import SwiftUI

struct BoosterTimerView: View {
 @StateObject private var store = StoreManager.shared
 @State private var showingAlert = false
 
 var body: some View {
     VStack {
         Text(store.currentTimeString)
             .font(.system(size: 24, weight: .bold))
             .onTapGesture {
                 showingAlert = true
             }
     }
     .alert("Accélérer le timer", isPresented: $showingAlert) {
         Button("Utiliser \(store.hoursNeeded) points") {
             store.skipWaitingTime()
         }
         Button("Annuler", role: .cancel) {}
     } message: {
         Text("Il vous faut \(store.hoursNeeded) points pour sauter cette attente.\nVous avez \(store.availablePoints) points disponibles.")
     }
 }
}
