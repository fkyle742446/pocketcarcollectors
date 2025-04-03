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
    @Published var purchaseError: String?
    
    private let productIdentifiers = Set([
        "com.pocketcarcollectors.100coins",
        "com.pocketcarcollectors.500coins"
    ])
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        print("🚀 Initializing IAPManager")
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                await self.handle(updatedTransaction: result)
            }
        }
    }
    
    private func handle(updatedTransaction transaction: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = transaction else {
            print("🚫 Unverified transaction")
            return
        }
        
        print("✅ Processing transaction: \(transaction.productID)")
        
        await MainActor.run {
            let collectionManager = CollectionManager.shared
            
            switch transaction.productID {
            case "com.pocketcarcollectors.100coins":
                collectionManager.coins += 100
                print("💰 Added 100 coins. New total: \(collectionManager.coins)")
                
            case "com.pocketcarcollectors.500coins":
                collectionManager.coins += 500
                print("💰 Added 500 coins. New total: \(collectionManager.coins)")
                
            default:
                print("⚠️ Unknown product ID: \(transaction.productID)")
            }
            
            // Save changes
            collectionManager.saveCollection()
            
            // Notify all observers
            NotificationCenter.default.post(name: .coinsDidUpdate, object: nil)
        }
        
        await transaction.finish()
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIdentifiers)
            print("📦 Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        purchaseInProgress = true
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await MainActor.run {
                        let collectionManager = CollectionManager.shared
                        
                        switch product.id {
                        case "com.pocketcarcollectors.100coins":
                            collectionManager.coins += 100
                            print("💰 Direct add: 100 coins. New total: \(collectionManager.coins)")
                            
                        case "com.pocketcarcollectors.500coins":
                            collectionManager.coins += 500
                            print("💰 Direct add: 500 coins. New total: \(collectionManager.coins)")
                            
                        default:
                            break
                        }
                        
                        // Save changes
                        collectionManager.saveCollection()
                        
                        // Notify all observers
                        NotificationCenter.default.post(name: .coinsDidUpdate, object: nil)
                    }
                    
                    await transaction.finish()
                    purchaseInProgress = false
                    return true
                    
                case .unverified:
                    throw PurchaseError.failedVerification
                }
                
            case .userCancelled:
                purchaseInProgress = false
                throw PurchaseError.cancelled
                
            case .pending:
                purchaseInProgress = false
                throw PurchaseError.pending
                
            @unknown default:
                purchaseInProgress = false
                throw PurchaseError.unknown
            }
        } catch {
            purchaseInProgress = false
            throw error
        }
    }
    
    enum PurchaseError: Error, LocalizedError {
        case failedVerification
        case cancelled
        case pending
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .failedVerification:
                return "Purchase verification failed"
            case .cancelled:
                return "Purchase cancelled"
            case .pending:
                return "Purchase pending"
            case .unknown:
                return "Unknown error occurred"
            }
        }
    }
}

extension Notification.Name {
    static let coinsDidUpdate = Notification.Name("coinsDidUpdate")
}
