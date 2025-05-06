import Foundation
import SwiftUI
import StoreKit

class AppUpdateChecker: ObservableObject {
    static let shared = AppUpdateChecker()
    private let lastCheckKey = "lastUpdateCheck"
    private let checkInterval: TimeInterval = 24 * 60 * 60 // Check once per day
    @Published var updateRequired = false
    @Published var updateAvailable = false
    
    private init() {
        Task {
            await checkForUpdate()
        }
    }
    
    func checkForUpdate() async -> Bool {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let url = URL(string: "https://itunes.apple.com/lookup?bundleId=pocket-car.pocket-car") else {
            return false
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let appStoreVersion = results.first?["version"] as? String {
                
                let current = currentVersion.split(separator: ".").map { Int($0) ?? 0 }
                let appStore = appStoreVersion.split(separator: ".").map { Int($0) ?? 0 }
                
                // Compare version numbers
                for i in 0..<min(current.count, appStore.count) {
                    if appStore[i] > current[i] {
                        await MainActor.run {
                            self.updateAvailable = true
                            // Force update if major version is different
                            self.updateRequired = appStore[0] > current[0]
                        }
                        return true
                    } else if current[i] > appStore[i] {
                        return false
                    }
                }
                
                // If all numbers are equal, longer version is newer
                let needsUpdate = appStore.count > current.count
                if needsUpdate {
                    await MainActor.run {
                        self.updateAvailable = true
                        self.updateRequired = appStore[0] > current[0]
                    }
                }
                return needsUpdate
            }
        } catch {
            print("Error checking for updates: \(error)")
        }
        
        return false
    }
    
    func openAppStore() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier,
              let url = URL(string: "itms-apps://itunes.apple.com/app/id\(bundleIdentifier)") else {
            return
        }
        
        Task { @MainActor in
            await UIApplication.shared.open(url)
        }
    }
    
    func showUpdateAlert() -> Alert {
        Alert(
            title: Text(updateRequired ? "Mise à jour requise" : "Mise à jour disponible"),
            message: Text(updateRequired ?
                        "Une mise à jour importante est disponible. Veuillez mettre à jour l'application pour continuer." :
                        "Une nouvelle version de l'application est disponible."),
            primaryButton: .default(Text("Mettre à jour")) {
                self.openAppStore()
            },
            secondaryButton: .cancel(Text("Plus tard")) {
                // Only allow cancel if update is not required
            }
        )
    }
    
    func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}
