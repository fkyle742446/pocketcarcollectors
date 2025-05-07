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
    @Published var productsLoaded = false
    
    private let productIdentifiers = Set([
        "com.pocketcarcollectors.pack100coins",
        "com.pocketcarcollectors.pack500coins"
    ])
    
    private var updateListenerTask: Task<Void, Error>?

    private var processedTransactionIDs: Set<UInt64> = []
    private let processedTransactionIDsKey = "processedTransactionIDs_v2_debug" // Changed key for fresh testing

    private init() {
        print("🚀 [IAPManager] Initializing...")
        loadProcessedTransactionIDs() 
        updateListenerTask = listenForTransactions()
        print("🚀 [IAPManager] Listener started.")
        
        Task {
            await loadProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    private func loadProcessedTransactionIDs() {
        print("⏳ [IAPManager] Loading processed transaction IDs from UserDefaults (key: \(processedTransactionIDsKey))...")
        let savedIDs = UserDefaults.standard.array(forKey: processedTransactionIDsKey) as? [NSNumber] ?? []
        self.processedTransactionIDs = Set(savedIDs.map { $0.uint64Value })
        print("✅ [IAPManager] Loaded \(self.processedTransactionIDs.count) processed transaction IDs: \(self.processedTransactionIDs)")
    }

    private func addProcessedTransactionID(_ transactionID: UInt64) {
        print("⏳ [IAPManager] Adding transaction ID \(transactionID) to in-memory set: \(processedTransactionIDs) -> will add \(transactionID)")
        processedTransactionIDs.insert(transactionID)
        let nsNumberArray = Array(processedTransactionIDs).map { NSNumber(value: $0) }
        UserDefaults.standard.set(nsNumberArray, forKey: processedTransactionIDsKey)
        
        // Force synchronization to try and ensure it's written before app might close
        let success = UserDefaults.standard.synchronize()
        print("💾 [IAPManager] Saved transaction ID \(transactionID) to UserDefaults. Synchronize success: \(success). Current in-memory IDs: \(processedTransactionIDs)")
        
        // Verify immediately what was written
        let reloadedIDs = UserDefaults.standard.array(forKey: processedTransactionIDsKey) as? [NSNumber] ?? []
        print("🔍 [IAPManager] UserDefaults check immediately after save for key '\(processedTransactionIDsKey)': count \(reloadedIDs.count), IDs \(reloadedIDs.map{$0.uint64Value})")
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            print("🎧 [IAPManager] Transaction listener task started.")
            for await result in Transaction.updates {
                print("🔔 [IAPManager] Received transaction update from Transaction.updates.")
                await self.handle(updatedTransaction: result)
            }
            print("🛑 [IAPManager] Transaction listener task finished (should not happen unless IAPManager is deinitialized).")
        }
    }
    
    private func handle(updatedTransaction verificationResult: VerificationResult<Transaction>) async {
        let transactionDetailsForLog: String
        var transactionForProcessing: Transaction? = nil

        switch verificationResult {
        case .verified(let verifiedTransaction):
            transactionDetailsForLog = "Verified - ProductID: \(verifiedTransaction.productID), ID: \(verifiedTransaction.id)"
            transactionForProcessing = verifiedTransaction
        case .unverified(let unverifiedTransaction, let verificationError):
            transactionDetailsForLog = "Unverified - Error: \(verificationError.localizedDescription)"
             print("🚫 [IAPManager] Unverified transaction. Error: \(verificationError.localizedDescription). Raw JWS: \(unverifiedTransaction)")
            return 
        }
        print("🔄 [IAPManager] Handling transaction from listener. Details: \(transactionDetailsForLog)")

        guard let transaction = transactionForProcessing else {
            print("❌ [IAPManager] No transaction available for processing after verification check.")
            return
        }
        
        let currentTransactionID = transaction.id
        print("🔍 [IAPManager] Transaction ID received from StoreKit: \(currentTransactionID). Current in-memory processedTransactionIDs BEFORE check: \(self.processedTransactionIDs)")

        // Primary check against in-memory set
        if self.processedTransactionIDs.contains(currentTransactionID) {
            print("‼️ [IAPManager] Transaction ID \(currentTransactionID) (ProductID: \(transaction.productID)) IS ALREADY IN processedTransactionIDs (in-memory check). Finishing again to be safe.")
            await transaction.finish()
            print("🏁 [IAPManager] Finished (again) transaction ID \(currentTransactionID) due to being already processed (in-memory).")
            return
        }
        
        // Paranoia check: Reload from UserDefaults just before processing THIS specific transaction.
        // This helps if the in-memory `self.processedTransactionIDs` was somehow not up-to-date
        // due to app lifecycle or other async issues.
        let persistedIDsArray = UserDefaults.standard.array(forKey: self.processedTransactionIDsKey) as? [NSNumber] ?? []
        let persistedIDsSet = Set(persistedIDsArray.map { $0.uint64Value })
        print("🤔 [IAPManager] Double-checking against UserDefaults for transaction ID \(currentTransactionID). Persisted IDs from UserDefaults: \(persistedIDsSet)")

        if persistedIDsSet.contains(currentTransactionID) {
            print("‼️ [IAPManager] Transaction ID \(currentTransactionID) (ProductID: \(transaction.productID)) IS ALREADY IN UserDefaults processedTransactionIDs (double-check). Updating in-memory set and finishing.")
            // Ensure in-memory set is also up-to-date
            self.processedTransactionIDs.insert(currentTransactionID)
            await transaction.finish()
            print("🏁 [IAPManager] Finished (again) transaction ID \(currentTransactionID) due to being already processed (UserDefaults double-check).")
            return
        }

        print("🆕 [IAPManager] Transaction ID \(currentTransactionID) (ProductID: \(transaction.productID)) is NOT in processedTransactionIDs (in-memory or persisted). Proceeding to credit.")
        
        var mutableTransaction = transaction 
        
        await MainActor.run {
            let collectionManager = CollectionManager.shared
            var coinsToAdd = 0
            
            switch mutableTransaction.productID {
            case "com.pocketcarcollectors.pack100coins":
                coinsToAdd = 100
            case "com.pocketcarcollectors.pack500coins":
                coinsToAdd = 500
            default:
                print("⚠️ [IAPManager] Unknown product ID in handle: \(mutableTransaction.productID) for transaction ID \(mutableTransaction.id)")
            }

            if coinsToAdd > 0 {
                print("💰 [IAPManager] Crediting \(coinsToAdd) coins for transaction ID \(mutableTransaction.id).")
                collectionManager.coins += coinsToAdd
                print("💾 [IAPManager] Saving collection after crediting coins...")
                collectionManager.saveCollection() 
                print("✅ [IAPManager] Collection saved. Current coins: \(collectionManager.coins)")
                
                NotificationCenter.default.post(name: .coinsDidUpdate, object: nil)
                
                // Mark this transaction ID as processed AFTER successfully crediting and saving
                self.addProcessedTransactionID(mutableTransaction.id) // This will also print the state of UserDefaults
            } else {
                print("ℹ️ [IAPManager] No coins to add for product ID \(mutableTransaction.productID) (transaction ID \(mutableTransaction.id)). Might be an unknown product or already handled.")
            }
        }
        
        print("⏳ [IAPManager] Attempting to finish transaction \(mutableTransaction.id) (ProductID: \(mutableTransaction.productID)) from handle(updatedTransaction:).")
        await mutableTransaction.finish()
        print("🏁 [IAPManager] Transaction \(mutableTransaction.id) finished call completed from handle(updatedTransaction:).")
    }

    // CORRECTED: Made static AND nonisolated
    static private nonisolated func localizedDescription(for verificationError: VerificationResult<Transaction>.VerificationError) -> String {
        // The VerificationError itself conforms to Error, so we can use its localizedDescription.
        // Switch on specific known cases if we want custom messages, otherwise default to its description.
        switch verificationError {
        case .invalidSignature:
            return "Invalid JWS signature for the transaction."
        case .invalidCertificateChain:
            return "The JWS certificate chain is invalid."
        // No other specific cases are directly part of VerificationResult<Transaction>.VerificationError as top-level enum cases.
        @unknown default:
            // For any other or future cases, its own localizedDescription should be sufficient.
            return verificationError.localizedDescription
        }
    }

    // CORRECTED: PurchaseError enum to correctly store the verification error
    // and provide a simplified description
    enum PurchaseError: Error, LocalizedError {
        case failedVerification(VerificationResult<Transaction>.VerificationError)
        case cancelled
        case pending
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .failedVerification(let verificationError):
                // Call the static helper method
                return "Purchase verification failed: \(IAPManager.localizedDescription(for: verificationError))"
            case .cancelled:
                return "Purchase cancelled"
            case .pending:
                return "Purchase pending (e.g., Ask to Buy)"
            case .unknown:
                return "Unknown error occurred"
            }
        }
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        await MainActor.run {
            print(" [IAPManager] Initiating purchase for product: \(product.id) - \(product.displayName)")
            purchaseInProgress = true
            purchaseError = nil
        }
        
        do {
            let result = try await product.purchase()
            print(" [IAPManager] Purchase call for \(product.id) returned.")
            
            switch result {
            case .success(let verificationResult):
                print(" [IAPManager] Purchase result success for \(product.id).")
                switch verificationResult {
                case .verified(let transaction):
                    print(" [IAPManager] Purchase for \(product.id) verified. Transaction ID: \(transaction.id). Listener will handle full processing.")
                    await MainActor.run { purchaseInProgress = false }
                    return true
                case .unverified(_, let verificationError): 
                    // CORRECTED: Explicitly call static method
                    let detailedErrorDescription = IAPManager.localizedDescription(for: verificationError)
                    print(" [IAPManager] Purchase for \(product.id) unverified. Error: \(detailedErrorDescription)")
                    await MainActor.run {
                        purchaseError = "Purchase verification failed: \(detailedErrorDescription)"
                        purchaseInProgress = false
                    }
                    throw PurchaseError.failedVerification(verificationError)
                }
                
            case .userCancelled:
                print(" [IAPManager] Purchase cancelled by user for \(product.id).")
                await MainActor.run { purchaseInProgress = false }
                throw PurchaseError.cancelled
                
            case .pending:
                print(" [IAPManager] Purchase pending for \(product.id). User needs to take action (e.g., Ask to Buy).")
                await MainActor.run {
                    purchaseError = "Purchase is pending approval."
                    purchaseInProgress = false 
                }
                return false 
                
            @unknown default:
                print(" [IAPManager] Unknown purchase result for \(product.id).")
                await MainActor.run {
                    purchaseError = "An unknown error occurred during purchase."
                    purchaseInProgress = false
                }
                throw PurchaseError.unknown
            }
        } catch let error as PurchaseError {
            print(" [IAPManager] PurchaseError during purchase of \(product.id): \(error.localizedDescription)")
            await MainActor.run { purchaseInProgress = false }
            throw error
        } catch {
            print(" [IAPManager] Generic error during purchase of \(product.id): \(error.localizedDescription)")
            await MainActor.run {
                purchaseError = error.localizedDescription
                purchaseInProgress = false
            }
            throw error
        }
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIdentifiers)
            print(" [IAPManager] Loaded \(products.count) products")
            await MainActor.run {
                productsLoaded = true
            }
        } catch {
            print(" [IAPManager] Failed to load products: \(error)")
            await MainActor.run {
                productsLoaded = false
            }
        }
    }
}

extension Notification.Name {
    static let coinsDidUpdate = Notification.Name("coinsDidUpdate")
}
