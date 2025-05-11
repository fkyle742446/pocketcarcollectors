import Foundation
import UIKit

class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    private let boosterCooldown: TimeInterval = 6 * 3600 // 6 heures
    private let dailyQuestCooldown: TimeInterval = 24 * 3600 // 24 heures

    private let timeCheatTolerance: TimeInterval = 60 // 60 secondes de tolérance
    private let forwardTimeCheatPenaltyFactor: Double = 1.5 // Pénalité: repousser le timer de 1.5x le temps avancé
    /// Avance minimale (en secondes) au-delà de laquelle la pénalité s'applique (ici 30 minutes)
    private let minAdvanceForPenalty: TimeInterval = 1800 // 30 minutes

    @Published var boosters: Int = 0 {
        didSet {
            UserDefaults.standard.set(boosters, forKey: "boosters")
            print("StoreManager: Boosters set to \(boosters). Saved to UserDefaults.")
        }
    }
    
    @Published var referralBoostersToOpen: Int = 0 {
        didSet {
            UserDefaults.standard.set(referralBoostersToOpen, forKey: "referralBoostersToOpen")
            print("StoreManager: ReferralBoostersToOpen set to \(referralBoostersToOpen). Saved to UserDefaults.")
        }
    }
    
    @Published var nextFreeBoosterDate: Date? {
        didSet {
            if let date = nextFreeBoosterDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "nextBoosterTimestamp_v2") // Changed key for safety
                print("StoreManager: nextFreeBoosterDate set to \(date). Saved timestamp \(date.timeIntervalSince1970).")
                // NotificationManager.shared.scheduleBoosterNotification(for: date) // We can uncomment this later if desired
            } else {
                UserDefaults.standard.removeObject(forKey: "nextBoosterTimestamp_v2")
                print("StoreManager: nextFreeBoosterDate set to nil. Removed timestamp from UserDefaults.")
            }
        }
    }
    
    @Published var nextDailyQuestDate: Date? {
        didSet {
            if let date = nextDailyQuestDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "nextDailyQuestTimestamp")
                print("StoreManager: nextDailyQuestDate set to \(date). Saved timestamp \(date.timeIntervalSince1970).")
                NotificationManager.shared.scheduleDailyQuestNotification(for: date)
            } else {
                UserDefaults.standard.removeObject(forKey: "nextDailyQuestTimestamp")
                print("StoreManager: nextDailyQuestDate set to nil. Removed timestamp from UserDefaults.")
            }
        }
    }
    
    private var referenceDeviceTimestampWhenTimerSet: TimeInterval? {
        get {
            UserDefaults.standard.object(forKey: "referenceDeviceTimestamp_v2") as? TimeInterval // Changed key
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: "referenceDeviceTimestamp_v2")
                print("StoreManager: referenceDeviceTimestampWhenTimerSet set to \(Date(timeIntervalSince1970: newValue)) (\(newValue)). Saved to UserDefaults.")
            } else {
                UserDefaults.standard.removeObject(forKey: "referenceDeviceTimestamp_v2")
                print("StoreManager: referenceDeviceTimestampWhenTimerSet set to nil. Removed from UserDefaults.")
            }
        }
    }
    
    private let lastValidatedBoosterTimestampKey = "lastValidatedTimestamp" // Renamed for clarity
    private let lastValidatedBoosterUptimeKey = "lastValidatedUptime"       // Renamed for clarity
    
    private let lastValidatedDailyQuestTimestampKey = "lastValidatedDailyQuestTimestamp"
    private let lastValidatedDailyQuestUptimeKey = "lastValidatedDailyQuestUptime"
    private let lastBackgroundTimestampKey = "lastBackgroundTimestamp" // Keeping for now if used elsewhere

    private init() {
        print("StoreManager: Initializing...")
        self.boosters = UserDefaults.standard.integer(forKey: "boosters")
        self.referralBoostersToOpen = UserDefaults.standard.integer(forKey: "referralBoostersToOpen")
        
        if !UserDefaults.standard.bool(forKey: "initialBoostersGiven_v2") { // Changed key
            self.boosters = 4
            UserDefaults.standard.set(true, forKey: "initialBoostersGiven_v2")
            print("StoreManager: Given initial 4 boosters.")
        }
        
        validateBoosterTimer()
        validateDailyQuestTimer()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        print("StoreManager: Initialized. Boosters: \(self.boosters), Referral Boosters: \(self.referralBoostersToOpen), NextFreeBoosterDate: \(String(describing: self.nextFreeBoosterDate)), NextDailyQuestDate: \(String(describing: self.nextDailyQuestDate))")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func appWillEnterForeground() {
        print("StoreManager: App will enter foreground. Validating timers.")
        validateBoosterTimer()
        validateDailyQuestTimer()
    }

    func validateBoosterTimer() {
        let currentTime = Date().timeIntervalSince1970
        let currentUptime = ProcessInfo.processInfo.systemUptime

        var validReferenceTimestamp = UserDefaults.standard.double(forKey: lastValidatedBoosterTimestampKey)
        let previousUptime = UserDefaults.standard.double(forKey: lastValidatedBoosterUptimeKey)
        
        if validReferenceTimestamp == 0 || previousUptime == 0 {
            print("StoreManager (Booster): Initializing booster timestamps. ValidRefTS: \(validReferenceTimestamp), PrevUptime: \(previousUptime)")
            if UserDefaults.standard.object(forKey: "nextBoosterTimestamp_v2") == nil { // Check if it was ever set
                nextFreeBoosterDate = Date(timeIntervalSince1970: currentTime)
                print("StoreManager (Booster): Initialized nextFreeBoosterDate to current time: \(nextFreeBoosterDate!)")
            } else if let storedTimestamp = UserDefaults.standard.object(forKey: "nextBoosterTimestamp_v2") as? TimeInterval {
                nextFreeBoosterDate = Date(timeIntervalSince1970: storedTimestamp)
                print("StoreManager (Booster): Loaded existing nextFreeBoosterDate: \(nextFreeBoosterDate!)")
            }
            UserDefaults.standard.set(currentTime, forKey: lastValidatedBoosterTimestampKey)
            UserDefaults.standard.set(currentUptime, forKey: lastValidatedBoosterUptimeKey)
            return
        }

        if currentTime < validReferenceTimestamp - timeCheatTolerance {
            let timeShiftDetected = validReferenceTimestamp - currentTime
            print("StoreManager (Booster): ⚠️ Time cheat detected (clock moved backwards by \(timeShiftDetected)s). Current: \(Date(timeIntervalSince1970:currentTime)), Ref: \(Date(timeIntervalSince1970:validReferenceTimestamp))")
            
            let newTargetUnlockTime = validReferenceTimestamp + boosterCooldown
            self.nextFreeBoosterDate = Date(timeIntervalSince1970: newTargetUnlockTime)
            
            print("StoreManager (Booster): Adjusted target unlock to \(self.nextFreeBoosterDate!) due to time cheat.")
            
            UserDefaults.standard.set(currentTime, forKey: lastValidatedBoosterTimestampKey)
            UserDefaults.standard.set(currentUptime, forKey: lastValidatedBoosterUptimeKey)
            return 
        }

        var didApplyForwardPenalty = false
        if currentUptime >= previousUptime {
            let wallTimeDelta = currentTime - validReferenceTimestamp 
            let uptimeDelta = currentUptime - previousUptime     
            let detectedJump = wallTimeDelta - uptimeDelta

            print("StoreManager (Booster): Forward check - WallTimeDelta: \(wallTimeDelta)s, UptimeDelta: \(uptimeDelta)s, DetectedJump: \(detectedJump)s")

            if detectedJump > minAdvanceForPenalty + timeCheatTolerance {
                print("StoreManager (Booster): ⚠️ Forward time cheat detected (Jump: \(detectedJump)s).")
                
                let penaltyMultiplier = self.forwardTimeCheatPenaltyFactor > 1.0 ? (self.forwardTimeCheatPenaltyFactor - 1.0) : 0.0
                let penaltyAmount = detectedJump * penaltyMultiplier 

                let newTargetUnlockTimeWithPenalty = currentTime + self.boosterCooldown + penaltyAmount
                self.nextFreeBoosterDate = Date(timeIntervalSince1970: newTargetUnlockTimeWithPenalty)
                
                print("StoreManager (Booster): Forward cheat penalized. Next booster at \(self.nextFreeBoosterDate!).")
                didApplyForwardPenalty = true
            } else {
                print("StoreManager (Booster): No forward time cheat detected or jump (\(detectedJump)s) is insignificant.")
            }
        } else { 
            print("StoreManager (Booster): Device reboot detected. Skipping forward time cheat detection.")
        }

        UserDefaults.standard.set(currentTime, forKey: lastValidatedBoosterTimestampKey)
        UserDefaults.standard.set(currentUptime, forKey: lastValidatedBoosterUptimeKey)

        if !didApplyForwardPenalty {
            if let storedTimestamp = UserDefaults.standard.object(forKey: "nextBoosterTimestamp_v2") as? TimeInterval {
                let storedDate = Date(timeIntervalSince1970: storedTimestamp)
                if self.nextFreeBoosterDate == nil || self.nextFreeBoosterDate! != storedDate { // Only update if nil or different
                    self.nextFreeBoosterDate = storedDate // Ensure it's loaded from storage if not penalized
                    print("StoreManager (Booster): Loaded/Re-synced nextFreeBoosterDate from UserDefaults: \(self.nextFreeBoosterDate!)")
                }
            } else if self.nextFreeBoosterDate == nil { // Should have been set at init, but as a fallback
                self.nextFreeBoosterDate = Date(timeIntervalSince1970: currentTime)
                print("StoreManager (Booster): Set nextFreeBoosterDate to current time as it was nil and no penalty applied.")
            }

            if let nextDate = self.nextFreeBoosterDate, currentTime >= nextDate.timeIntervalSince1970 {
                print("StoreManager (Booster): Booster is available (current time \(Date(timeIntervalSince1970:currentTime)) is past nextFreeBoosterDate \(nextDate)).")
            } else if let nextDate = self.nextFreeBoosterDate {
                print("StoreManager (Booster): Booster is still on cooldown until \(nextDate). No cheat detected impacting timer.")
            }
        }
    }

    func validateDailyQuestTimer() {
        let currentTime = Date().timeIntervalSince1970
        let currentUptime = ProcessInfo.processInfo.systemUptime

        var validReferenceTimestamp = UserDefaults.standard.double(forKey: lastValidatedDailyQuestTimestampKey)
        let previousUptime = UserDefaults.standard.double(forKey: lastValidatedDailyQuestUptimeKey)

        if validReferenceTimestamp == 0 || previousUptime == 0 {
            print("StoreManager (DailyQuest): Initializing daily quest timestamps. ValidRefTS: \(validReferenceTimestamp), PrevUptime: \(previousUptime)")
            if UserDefaults.standard.object(forKey: "nextDailyQuestTimestamp") == nil { // Check if it was ever set
                nextDailyQuestDate = Date(timeIntervalSince1970: currentTime)
                print("StoreManager (DailyQuest): Initialized nextDailyQuestDate to current time: \(self.nextDailyQuestDate!)")
            } else if let storedTimestamp = UserDefaults.standard.object(forKey: "nextDailyQuestTimestamp") as? TimeInterval {
                nextDailyQuestDate = Date(timeIntervalSince1970: storedTimestamp)
                print("StoreManager (DailyQuest): Loaded existing nextDailyQuestDate: \(self.nextDailyQuestDate!)")
            }
            UserDefaults.standard.set(currentTime, forKey: lastValidatedDailyQuestTimestampKey)
            UserDefaults.standard.set(currentUptime, forKey: lastValidatedDailyQuestUptimeKey)
            return
        }

        if currentTime < validReferenceTimestamp - timeCheatTolerance {
            let timeShiftDetected = validReferenceTimestamp - currentTime
            print("StoreManager (DailyQuest): ⚠️ Time cheat detected (clock moved backwards by \(timeShiftDetected)s).")
            
            let newTargetUnlockTime = validReferenceTimestamp + dailyQuestCooldown
            self.nextDailyQuestDate = Date(timeIntervalSince1970: newTargetUnlockTime)
            
            print("StoreManager (DailyQuest): Adjusted target unlock to \(self.nextDailyQuestDate!) due to time cheat.")
            
            UserDefaults.standard.set(currentTime, forKey: lastValidatedDailyQuestTimestampKey)
            UserDefaults.standard.set(currentUptime, forKey: lastValidatedDailyQuestUptimeKey)
            return
        }

        var didApplyForwardPenalty = false
        if currentUptime >= previousUptime {
            let wallTimeDelta = currentTime - validReferenceTimestamp
            let uptimeDelta = currentUptime - previousUptime
            let detectedJump = wallTimeDelta - uptimeDelta

            print("StoreManager (DailyQuest): Forward check - WallTimeDelta: \(wallTimeDelta)s, UptimeDelta: \(uptimeDelta)s, DetectedJump: \(detectedJump)s")

            if detectedJump > minAdvanceForPenalty + timeCheatTolerance {
                print("StoreManager (DailyQuest): ⚠️ Forward time cheat detected (Jump: \(detectedJump)s).")
                
                let penaltyMultiplier = self.forwardTimeCheatPenaltyFactor > 1.0 ? (self.forwardTimeCheatPenaltyFactor - 1.0) : 0.0
                let penaltyAmount = detectedJump * penaltyMultiplier

                let newTargetUnlockTimeWithPenalty = currentTime + self.dailyQuestCooldown + penaltyAmount
                self.nextDailyQuestDate = Date(timeIntervalSince1970: newTargetUnlockTimeWithPenalty)
                
                print("StoreManager (DailyQuest): Forward cheat penalized. Next quest at \(self.nextDailyQuestDate!).")
                didApplyForwardPenalty = true
            } else {
                print("StoreManager (DailyQuest): No forward time cheat detected or jump (\(detectedJump)s) is insignificant.")
            }
        } else {
            print("StoreManager (DailyQuest): Device reboot detected. Skipping forward time cheat detection.")
        }

        UserDefaults.standard.set(currentTime, forKey: lastValidatedDailyQuestTimestampKey)
        UserDefaults.standard.set(currentUptime, forKey: lastValidatedDailyQuestUptimeKey)

        if !didApplyForwardPenalty {
            if let storedTimestamp = UserDefaults.standard.object(forKey: "nextDailyQuestTimestamp") as? TimeInterval {
                let storedDate = Date(timeIntervalSince1970: storedTimestamp)
                if self.nextDailyQuestDate == nil || self.nextDailyQuestDate! != storedDate { // Only update if nil or different
                    self.nextDailyQuestDate = storedDate // Ensure it's loaded from storage if not penalized
                    print("StoreManager (DailyQuest): Loaded/Re-synced nextDailyQuestDate from UserDefaults: \(self.nextDailyQuestDate!)")
                }
            } else if self.nextDailyQuestDate == nil { // Should have been set at init, but as a fallback
                self.nextDailyQuestDate = Date(timeIntervalSince1970: currentTime)
                print("StoreManager (DailyQuest): Set nextDailyQuestDate to current time as it was nil and no penalty applied.")
            }

            if let nextDate = self.nextDailyQuestDate, currentTime >= nextDate.timeIntervalSince1970 {
                print("StoreManager (DailyQuest): Daily Quest is available (current time \(Date(timeIntervalSince1970:currentTime)) is past nextDailyQuestDate \(nextDate)).")
            } else if let nextDate = self.nextDailyQuestDate {
                print("StoreManager (DailyQuest): Daily Quest is still on cooldown until \(nextDate). No cheat detected impacting timer.")
            }
        }
    }
    
    func useBooster() {
        print("StoreManager: useBooster called. Current boosters: \(boosters)")
        if boosters > 0 {
            boosters -= 1
            
            if boosters == 0 {
                if self.nextFreeBoosterDate == nil || self.nextFreeBoosterDate! <= Date() {
                    print("StoreManager: Last booster used. Starting new booster timer.")
                    startNewBoosterTimer(from: Date().timeIntervalSince1970)
                } else {
                    print("StoreManager: Last booster used, but a booster timer is already active for \(self.nextFreeBoosterDate!). Not starting a new one.")
                }
            }
            print("StoreManager: Booster used. Remaining: \(boosters)")
        } else {
            print("StoreManager: Attempted to use booster, but none available.")
        }
    }

    func useReferralBooster() {
        print("StoreManager: useReferralBooster called. Current referral boosters: \(referralBoostersToOpen)")
        if referralBoostersToOpen > 0 {
            referralBoostersToOpen -= 1
            print("StoreManager: Referral booster used. Remaining: \(referralBoostersToOpen)")
        } else {
            print("StoreManager: Attempted to use referral booster, but none available.")
        }
    }

    private func startNewBoosterTimer(from startTime: TimeInterval) {
        let newTargetUnlockTime = startTime + boosterCooldown
        self.nextFreeBoosterDate = Date(timeIntervalSince1970: newTargetUnlockTime)
        
        print("StoreManager: 🕒 Started new booster timer. Next at: \(self.nextFreeBoosterDate!).")
    }

    func claimDailyQuest() {
        print("StoreManager (DailyQuest): Daily Quest claimed/completed.")
        startNewDailyQuestTimer(from: Date().timeIntervalSince1970)
    }

    private func startNewDailyQuestTimer(from startTime: TimeInterval) {
        let newTargetUnlockTime = startTime + dailyQuestCooldown
        self.nextDailyQuestDate = Date(timeIntervalSince1970: newTargetUnlockTime) // This will trigger the didSet and schedule notification
        
        UserDefaults.standard.set(startTime, forKey: lastValidatedDailyQuestTimestampKey)
        UserDefaults.standard.set(ProcessInfo.processInfo.systemUptime, forKey: lastValidatedDailyQuestUptimeKey)
        
        print("StoreManager (DailyQuest): 🕒 Started new daily quest timer. Next quest at: \(self.nextDailyQuestDate!).")
    }
}
