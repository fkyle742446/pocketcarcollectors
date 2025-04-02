import Foundation
import SwiftUI
import StoreKit

class AppUpdateChecker: ObservableObject {
    static let shared = AppUpdateChecker()
    private let lastCheckKey = "lastUpdateCheck"
    private let checkInterval: TimeInterval = 24 * 60 * 60 // Check once per day
    
    private init() {}
    
    func checkForUpdate() async -> Bool {
        // Simulation en mode DEBUG
        #if DEBUG
        return true
        #else
        do {
            let items = try await Task.detached(priority: .utility) {
                try await Bundle.main.appStoreReceiptURL.map { url in
                    let data = try Data(contentsOf: url)
                    return data.count > 0
                } ?? false
            }.value
            return items
        } catch {
            print("Failed to check for updates: \(error)")
            return false
        }
        #endif
    }
    
    func openAppStore() {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id6743163346") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}
