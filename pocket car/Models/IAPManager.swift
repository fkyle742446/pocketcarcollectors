import StoreKit
import SwiftUI

@MainActor
class IAPManager: ObservableObject {
    static let shared = IAPManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseInProgress = false
    
    private let productIdentifiers = [
        "com.pocketcarcollectors.100coins",
        "com.pocketcarcollectors.500coins"
    ]
    
    func loadProducts() async {
        do {
            print("🔄 Starting to load products...")
            var loadedProducts = try await Product.products(for: Set(productIdentifiers))
            // Sort products to show 100 coins pack first
            loadedProducts.sort { product1, product2 in
                return product1.id.contains("100") && !product2.id.contains("100")
            }
            self.products = loadedProducts
            
            if products.isEmpty {
                print("⚠️ No products were loaded!")
            } else {
                print("✅ Successfully loaded \(products.count) products:")
                for product in products {
                    print("📦 Product: \(product.id)")
                    print("   - Name: \(product.displayName)")
                    print("   - Price: \(product.displayPrice)")
                    print("   - Description: \(product.description)")
                }
            }
        } catch {
            print("❌ Failed to load products:", error.localizedDescription)
        }
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        purchaseInProgress = true
        print("🛒 Starting purchase for: \(product.id)")
        
        defer {
            purchaseInProgress = false
        }
        
        do {
            let result = try await product.purchase()
            print("📦 Purchase result received")
            
            switch result {
            case .success(let verification):
                print("✅ Purchase success, verifying...")
                switch verification {
                case .verified(let transaction):
                    print("✅ Transaction verified: \(transaction.productID)")
                    // Important: Finish the transaction
                    await transaction.finish()
                    return true
                    
                case .unverified(let transaction, let error):
                    print("❌ Transaction verification failed:")
                    print("   - Product ID: \(transaction.productID)")
                    print("   - Error: \(error.localizedDescription)")
                    throw PurchaseError.failedVerification(error)
                }
                
            case .userCancelled:
                print("⚠️ User cancelled purchase")
                throw PurchaseError.userCancelled
                
            case .pending:
                print("⏳ Purchase is pending approval")
                throw PurchaseError.pending
                
            @unknown default:
                print("❌ Unknown purchase result")
                throw PurchaseError.unknown
            }
        } catch is StoreKitError {
            print("❌ StoreKit error occurred")
            throw PurchaseError.storeKitError
        } catch {
            print("❌ Unexpected error: \(error.localizedDescription)")
            throw error
        }
    }
    
    enum PurchaseError: Error, LocalizedError {
        case failedVerification(Error)
        case userCancelled
        case pending
        case unknown
        case storeKitError
        
        var errorDescription: String? {
            switch self {
            case .failedVerification(let error):
                return "Échec de la vérification: \(error.localizedDescription)"
            case .userCancelled:
                return "Achat annulé"
            case .pending:
                return "Achat en attente d'approbation"
            case .storeKitError:
                return "Erreur de StoreKit"
            case .unknown:
                return "Une erreur inconnue s'est produite"
            }
        }
    }
}
