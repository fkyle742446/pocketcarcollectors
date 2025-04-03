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
            let savedDate = Date(timeIntervalSince1970: savedTimestamp)
            
            if currentTime >= savedTimestamp {
                let hoursElapsed = Int((currentTime - savedTimestamp) / 3600)
                let boostersToAdd = min(hoursElapsed / 6, 1)  // Max 1 booster
                
                if boostersToAdd > 0 {
                    self.boosters += boostersToAdd
                    // Set next booster time 6 hours from now
                    self.nextFreeBoosterDate = Date().addingTimeInterval(6 * 3600)
                } else {
                    // Keep the existing next booster date
                    self.nextFreeBoosterDate = savedDate
                }
            } else {
                self.nextFreeBoosterDate = savedDate
            }
        } else if self.boosters == 0 {
            // If no saved timestamp and no boosters, start timer
            self.nextFreeBoosterDate = Date().addingTimeInterval(6 * 3600)
        }
        
        self.lastKnownTimestamp = Date().timeIntervalSince1970
    }
    
    func useBooster() {
        if boosters > 0 {
            boosters -= 1
            
            // Set next booster time if no more boosters
            if boosters == 0 {
                let currentTime = Date().timeIntervalSince1970
                let nextTime = currentTime + (6 * 3600)
                nextFreeBoosterDate = Date(timeIntervalSince1970: nextTime)
                lastKnownTimestamp = currentTime
                
                print("🕒 Setting next booster time to: \(nextFreeBoosterDate!)")
                if let nextDate = nextFreeBoosterDate {
                    NotificationManager.shared.scheduleBoosterNotification(for: nextDate)
                }
            }
            
            print("Booster used. Remaining: \(boosters)")
        }
    }
    
    func checkForFreeBooster() {
        guard let nextDate = nextFreeBoosterDate else { return }
        let currentTime = Date().timeIntervalSince1970
        let nextTimestamp = nextDate.timeIntervalSince1970
        
        print("⏱ Checking for free booster - Current time: \(Date())")
        print("⏰ Next booster time: \(nextDate)")
        
        if currentTime >= nextTimestamp {
            boosters += 1
            
            if boosters == 1 {
                // Start new timer only if this was the first booster
                let newDate = Date().addingTimeInterval(6 * 3600)
                nextFreeBoosterDate = newDate
                print("🆕 Scheduling next booster notification for: \(newDate)")
                NotificationManager.shared.scheduleBoosterNotification(for: newDate)
            } else {
                nextFreeBoosterDate = nil
            }
            
            lastKnownTimestamp = currentTime
            print("Free booster added. Now have: \(boosters)")
        }
    }
}
