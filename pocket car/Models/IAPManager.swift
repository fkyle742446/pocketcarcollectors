import StoreKit

@MainActor
class IAPManager: ObservableObject {
    static let shared = IAPManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseInProgress = false
    
    private let productIdentifiers = [
        "com.pocketcarcollectors.100coins",
        "com.pocketcarcollectors.500coins"
    ]
    
    enum PurchaseError: Error {
        case failedVerification
        case cancelled
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIdentifiers)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    return true
                case .unverified:
                    throw PurchaseError.failedVerification
                }
            case .userCancelled:
                throw PurchaseError.cancelled
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            throw error
        }
    }
}
