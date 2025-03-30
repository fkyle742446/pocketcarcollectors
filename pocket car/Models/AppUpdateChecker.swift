import Foundation
import SwiftUI

class AppUpdateChecker {
    static let shared = AppUpdateChecker()
    private let lastCheckKey = "lastUpdateCheck"
    private let checkInterval: TimeInterval = 24 * 60 * 60 // Check once per day
    
    func checkForUpdate() async -> Bool {
        // Check if we already checked recently
        if let lastCheck = UserDefaults.standard.object(forKey: lastCheckKey) as? Date {
            let elapsed = Date().timeIntervalSince(lastCheck)
            if elapsed < checkInterval {
                return false
            }
        }
        
        // Update last check time
        UserDefaults.standard.set(Date(), forKey: lastCheckKey)
        
        // Your app's bundle ID
        guard let bundleId = Bundle.main.bundleIdentifier else { return false }
        
        // Current installed version
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return false
        }
        
        // Fetch App Store version
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)") else {
            return false
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let appStoreVersion = results.first?["version"] as? String else {
                return false
            }
            
            // Compare versions
            return compareVersions(appStore: appStoreVersion, current: currentVersion)
        } catch {
            print("Error checking for updates: \(error)")
            return false
        }
    }
    
    private func compareVersions(appStore: String, current: String) -> Bool {
        let appStoreComponents = appStore.split(separator: ".").map { Int($0) ?? 0 }
        let currentComponents = current.split(separator: ".").map { Int($0) ?? 0 }
        
        for i in 0..<max(appStoreComponents.count, currentComponents.count) {
            let appStore = i < appStoreComponents.count ? appStoreComponents[i] : 0
            let current = i < currentComponents.count ? currentComponents[i] : 0
            
            if appStore > current {
                return true
            } else if appStore < current {
                return false
            }
        }
        return false
    }
    
    func openAppStore() {
        guard let bundleId = Bundle.main.bundleIdentifier,
              let url = URL(string: "https://apps.apple.com/app/id\(bundleId)") else {
            return
        }
        
        Task { @MainActor in
            await UIApplication.shared.open(url)
        }
    }
}