import StoreKit

@MainActor
class IAPManager: ObservableObject {
    static let shared = IAPManager()
    
    #if DEBUG
    static let isTestMode = true
    #else
    static let isTestMode = false
    #endif
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseInProgress = false
    
    @Published var boosters: Int = 0 {
        didSet {
            UserDefaults.standard.set(boosters, forKey: "boosters")
        }
    }
    
    @Published var nextFreeBoosterDate: Date? {
        didSet {
            if let date = nextFreeBoosterDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "nextBoosterTimestamp")
            } else {
                UserDefaults.standard.removeObject(forKey: "nextBoosterTimestamp")
            }
        }
    }
    
    private var appOpenCount: Int {
        get { UserDefaults.standard.integer(forKey: "appOpenCount") }
        set { UserDefaults.standard.set(newValue, forKey: "appOpenCount") }
    }
    
    private var hasRequestedReview: Bool {
        get { UserDefaults.standard.bool(forKey: "hasRequestedReview") }
        set { UserDefaults.standard.set(newValue, forKey: "hasRequestedReview") }
    }
    
    @Published private var cheatAttempts: Int = 0 {
        didSet {
            UserDefaults.standard.set(cheatAttempts, forKey: "cheatAttempts")
        }
    }
    
    private let productIdentifiers = [
        "com.pocketcarcollectors.100coins",
        "com.pocketcarcollectors.500coins"
    ]
    
    private let userDefaults = UserDefaults.standard
    private let lastTimestampKey = "lastTimestampKey"
    private let maxTimeJump = 6 * 3600.0 // 6 heures maximum de saut
    
    private var lastKnownTimestamp: TimeInterval {
        get {
            userDefaults.double(forKey: lastTimestampKey)
        }
        set {
            userDefaults.set(newValue, forKey: lastTimestampKey)
        }
    }
    
    enum PurchaseError: Error {
        case failedVerification
        case cancelled
    }
    
    private init() {
        self.boosters = UserDefaults.standard.integer(forKey: "boosters")
        self.cheatAttempts = UserDefaults.standard.integer(forKey: "cheatAttempts")
        
        if userDefaults.double(forKey: lastTimestampKey) == 0 {
            lastKnownTimestamp = Date().timeIntervalSince1970
        }
        
        if let savedTimestamp = UserDefaults.standard.object(forKey: "nextBoosterTimestamp") as? TimeInterval {
            self.nextFreeBoosterDate = Date(timeIntervalSince1970: savedTimestamp)
        }
    }
    
    private func validateTimeAndApplyPenalty(_ currentTime: TimeInterval) -> Bool {
        let timeDifference = currentTime - lastKnownTimestamp
        
        if timeDifference < 0 {
            applyCheatPenalty()
            return false
        }
        
        if timeDifference > maxTimeJump {
            applyCheatPenalty()
            return false
        }
        
        return true
    }
    
    private func applyCheatPenalty() {
        cheatAttempts += 1
        
        let penaltyHours = Double(min(24 * cheatAttempts, 168))
        nextFreeBoosterDate = Date(timeIntervalSinceNow: penaltyHours * 3600)
        
        NotificationCenter.default.post(
            name: Notification.Name("CheatDetected"),
            object: nil,
            userInfo: ["penaltyHours": penaltyHours]
        )
    }
    
    func checkForReviewRequest() {
        appOpenCount += 1
        
        if appOpenCount >= 5 && !hasRequestedReview {
            NotificationManager.shared.scheduleReviewNotification()
            hasRequestedReview = true
        }
    }
    
    func checkForFreeBooster() {
        let currentTime = Date().timeIntervalSince1970
        
        guard validateTimeAndApplyPenalty(currentTime) else {
            lastKnownTimestamp = currentTime
            return
        }
        
        if let nextDate = nextFreeBoosterDate {
            if Date() >= nextDate {
                boosters += 1
                nextFreeBoosterDate = Date(timeIntervalSinceNow: 6 * 3600)
                cheatAttempts = max(0, cheatAttempts - 1)
                NotificationManager.shared.scheduleBoosterNotification(for: nextFreeBoosterDate!)
            }
        } else {
            nextFreeBoosterDate = Date(timeIntervalSinceNow: 6 * 3600)
            NotificationManager.shared.scheduleBoosterNotification(for: nextFreeBoosterDate!)
        }
        
        lastKnownTimestamp = currentTime
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIdentifiers)
            print("Successfully loaded \(products.count) products:")
            for product in products {
                print("- \(product.id): \(product.displayName) (\(product.displayPrice))")
            }
        } catch {
            print("Failed to load products: \(error)")
            if IAPManager.isTestMode {
                print("⚠️ In test mode: Make sure you're signed in with a Sandbox account in Settings")
                print("⚠️ Products need to be configured in App Store Connect")
            }
        }
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        
        if IAPManager.isTestMode {
            print("🚀 Starting purchase for \(product.id)")
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                if IAPManager.isTestMode {
                    print("✅ Purchase success, verifying transaction")
                }
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    if IAPManager.isTestMode {
                        print("✅ Transaction verified and finished")
                    }
                    return true
                case .unverified:
                    if IAPManager.isTestMode {
                        print("❌ Transaction verification failed")
                    }
                    throw PurchaseError.failedVerification
                }
            case .userCancelled:
                if IAPManager.isTestMode {
                    print("❌ Purchase cancelled by user")
                }
                throw PurchaseError.cancelled
            case .pending:
                if IAPManager.isTestMode {
                    print("⏳ Purchase pending")
                }
                return false
            @unknown default:
                if IAPManager.isTestMode {
                    print("❌ Unknown purchase state")
                }
                return false
            }
        } catch {
            if IAPManager.isTestMode {
                print("❌ Purchase error: \(error)")
            }
            throw error
        }
    }
}
