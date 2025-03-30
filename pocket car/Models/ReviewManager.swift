import Foundation
import StoreKit

class ReviewManager: ObservableObject {
    static let shared = ReviewManager()
    
    private let defaults = UserDefaults.standard
    private let triggeredMilestonesKey = "triggeredMilestones"
    @Published var showMilestoneAlert = false
    @Published var currentMilestone: Int = 0
    
    private var triggeredMilestones: Set<Int> {
        get {
            let array = defaults.array(forKey: triggeredMilestonesKey) as? [Int] ?? []
            return Set(array)
        }
        set {
            defaults.set(Array(newValue), forKey: triggeredMilestonesKey)
        }
    }
    
    func checkMilestone(collectionProgress: Double) {
        let milestone = Int(collectionProgress * 100)
        let milestones = [25, 50, 75]
        
        if milestones.contains(milestone) && !triggeredMilestones.contains(milestone) {
            currentMilestone = milestone
            triggeredMilestones.insert(milestone)
            showMilestoneAlert = true
        }
    }
    
    func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
