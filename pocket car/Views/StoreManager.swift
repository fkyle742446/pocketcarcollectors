import Foundation

class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
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
    
    private var lastKnownTimestamp: TimeInterval {
        get {
            UserDefaults.standard.double(forKey: "lastKnownTimestamp")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastKnownTimestamp")
        }
    }
    
    private init() {
        if UserDefaults.standard.double(forKey: "lastKnownTimestamp") == 0 {
            self.lastKnownTimestamp = Date().timeIntervalSince1970
        }
        
        self.boosters = UserDefaults.standard.integer(forKey: "boosters")
        
        if !UserDefaults.standard.bool(forKey: "initialBoostersGiven") {
            self.boosters = 4
            UserDefaults.standard.set(true, forKey: "initialBoostersGiven")
            UserDefaults.standard.set(self.boosters, forKey: "boosters")
        }
        
        if let savedTimestamp = UserDefaults.standard.object(forKey: "nextBoosterTimestamp") as? TimeInterval {
            let currentTime = Date().timeIntervalSince1970
            
            if currentTime < self.lastKnownTimestamp {
                self.boosters = 0
                self.nextFreeBoosterDate = Date().addingTimeInterval(6 * 3600)
                self.lastKnownTimestamp = currentTime
                return
            }
            
            let savedDate = Date(timeIntervalSince1970: savedTimestamp)
            self.nextFreeBoosterDate = savedDate
            
            if currentTime >= savedTimestamp {
                let timeDifference = currentTime - self.lastKnownTimestamp
                let expectedBoosters = Int(timeDifference / (6 * 3600))
                
                let maxAccumulatedBoosters = 1
                self.boosters += min(expectedBoosters, maxAccumulatedBoosters)
                
                if self.boosters > 0 {
                    self.nextFreeBoosterDate = nil
                }
            }
        }
        
        self.lastKnownTimestamp = Date().timeIntervalSince1970
    }
    
    func useBooster() {
        if boosters > 0 {
            boosters -= 1
            let currentTime = Date().timeIntervalSince1970
            let nextTimestamp = currentTime + (6 * 3600)
            nextFreeBoosterDate = Date(timeIntervalSince1970: nextTimestamp)
            lastKnownTimestamp = currentTime
            print("Booster used. Remaining: \(boosters)")
        }
    }
    
    func checkForFreeBooster() {
        guard let nextDate = nextFreeBoosterDate else { return }
        let currentTime = Date().timeIntervalSince1970
        let nextTimestamp = nextDate.timeIntervalSince1970
        
        if currentTime < lastKnownTimestamp {
            boosters = 0
            nextFreeBoosterDate = Date().addingTimeInterval(6 * 3600)
            lastKnownTimestamp = currentTime
            return
        }
        
        if currentTime >= nextTimestamp {
            let timeDifference = currentTime - lastKnownTimestamp
            if timeDifference <= (6 * 3600) {
                boosters += 1
                nextFreeBoosterDate = nil
                lastKnownTimestamp = currentTime
                print("Free booster added. Now have: \(boosters)")
            } else {
                boosters = 0
                nextFreeBoosterDate = Date().addingTimeInterval(6 * 3600)
                lastKnownTimestamp = currentTime
            }
        }
    }
}
