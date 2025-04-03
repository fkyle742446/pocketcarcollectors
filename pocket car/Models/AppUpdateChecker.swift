import Foundation
import SwiftUI
import StoreKit

class AppUpdateChecker: ObservableObject {
    static let shared = AppUpdateChecker()
    private let lastCheckKey = "lastUpdateCheck"
    private let checkInterval: TimeInterval = 24 * 60 * 60 // Check once per day
    
    private init() {}
    
    func checkForUpdate() async -> Bool {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let bundleIdentifier = Bundle.main.bundleIdentifier,
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
                        return true
                    } else if current[i] > appStore[i] {
                        return false
                    }
                }
                
                // If all numbers are equal, longer version is newer
                return appStore.count > current.count
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
    
    func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}
