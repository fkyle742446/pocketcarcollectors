import Foundation
import UIKit

class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    private let boosterCooldown: TimeInterval = 6 * 3600 // 6 heures
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
    
    @Published var nextFreeBoosterDate: Date? {
        didSet {
            if let date = nextFreeBoosterDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "nextBoosterTimestamp_v2") // Changed key for safety
                print("StoreManager: nextFreeBoosterDate set to \(date). Saved timestamp \(date.timeIntervalSince1970).")
            } else {
                UserDefaults.standard.removeObject(forKey: "nextBoosterTimestamp_v2")
                print("StoreManager: nextFreeBoosterDate set to nil. Removed timestamp from UserDefaults.")
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
    
    private let lastValidatedTimestampKey = "lastValidatedTimestamp"
    private let lastBackgroundTimestampKey = "lastBackgroundTimestamp" // Keep if used elsewhere, though new logic focuses on lastValidated
    private let lastValidatedUptimeKey = "lastValidatedUptime"

    private init() {
        print("StoreManager: Initializing...")
        self.boosters = UserDefaults.standard.integer(forKey: "boosters")
        
        if !UserDefaults.standard.bool(forKey: "initialBoostersGiven_v2") { // Changed key
            self.boosters = 4
            UserDefaults.standard.set(true, forKey: "initialBoostersGiven_v2")
            // UserDefaults.standard.set(self.boosters, forKey: "boosters") // Déjà fait par le didSet de boosters
            print("StoreManager: Given initial 4 boosters.")
        }
        
        validateAndRetrieveTimestamps() // This will now use the new logic
        
        // S'abonner aux notifications de cycle de vie de l'application
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        print("StoreManager: Initialized. Boosters: \(self.boosters), NextFreeDate: \(String(describing: self.nextFreeBoosterDate)), ReferenceDeviceTS: \(String(describing: self.referenceDeviceTimestampWhenTimerSet))")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func appWillEnterForeground() {
        print("StoreManager: App will enter foreground. Checking and validating booster timer.")
        validateAndRetrieveTimestamps()
    }

    func validateAndRetrieveTimestamps() {
        let currentTime = Date().timeIntervalSince1970
        let currentUptime = ProcessInfo.processInfo.systemUptime

        var validReferenceTimestamp = UserDefaults.standard.double(forKey: lastValidatedTimestampKey)
        let previousUptime = UserDefaults.standard.double(forKey: lastValidatedUptimeKey)
        
        let lastBackgroundTime = UserDefaults.standard.double(forKey: lastBackgroundTimestampKey)


        // --- Handling initialization or missing previous uptime data ---
        if validReferenceTimestamp == 0 || previousUptime == 0 { // MODIFIED: Check previousUptime as well
            print("StoreManager: Initializing timestamps. ValidRefTS: \(validReferenceTimestamp), PrevUptime: \(previousUptime)")
            if nextFreeBoosterDate == nil {
                // On first ever run, or if data was cleared, make booster available immediately.
                nextFreeBoosterDate = Date(timeIntervalSince1970: currentTime)
                print("StoreManager: Initialized nextFreeBoosterDate to current time: \(nextFreeBoosterDate!)")
            }
            UserDefaults.standard.set(currentTime, forKey: lastValidatedTimestampKey)
            UserDefaults.standard.set(currentUptime, forKey: lastValidatedUptimeKey)
            return
        }

        // --- Backward Time Cheat Detection (Clock moved backwards) ---
        if currentTime < validReferenceTimestamp - timeCheatTolerance {
            let timeShiftDetected = validReferenceTimestamp - currentTime
            print("StoreManager: ⚠️ Time cheat detected (clock moved backwards by \(timeShiftDetected)s). Current: \(Date(timeIntervalSince1970:currentTime)), Ref: \(Date(timeIntervalSince1970:validReferenceTimestamp))")
            
            // Penalize by setting the next booster unlock relative to the time it "should" have been
            let newTargetUnlockTime = validReferenceTimestamp + boosterCooldown
            self.nextFreeBoosterDate = Date(timeIntervalSince1970: newTargetUnlockTime)
            
            print("StoreManager: Adjusted target unlock to \(self.nextFreeBoosterDate!) due to time cheat.")
            
            UserDefaults.standard.set(currentTime, forKey: lastValidatedTimestampKey) // Update to current (though penalized) time
            UserDefaults.standard.set(currentUptime, forKey: lastValidatedUptimeKey)
            return // Exit after handling backward cheat
        }

        // --- New Forward Time Cheat Detection (Clock jumped forward unnaturally) ---
        var didApplyForwardPenalty = false
        // Only perform this check if uptime is progressing normally (no reboot detected)
        if currentUptime >= previousUptime {
            let wallTimeDelta = currentTime - validReferenceTimestamp // Time passed according to wall clock
            let uptimeDelta = currentUptime - previousUptime     // Time passed according to device uptime

            // This is the crucial part: how much more did the wall clock advance than the device's own uptime?
            // A small positive value is normal (NTP syncs, system processing delays).
            let detectedJump = wallTimeDelta - uptimeDelta

            print("StoreManager: Forward check - WallTimeDelta: \(wallTimeDelta)s, UptimeDelta: \(uptimeDelta)s, DetectedJump: \(detectedJump)s")

            // If the detected jump (beyond normal passage of time) is significant
            if detectedJump > minAdvanceForPenalty + timeCheatTolerance {
                print("StoreManager: ⚠️ Forward time cheat detected (Wall clock advanced \(wallTimeDelta)s, Uptime advanced \(uptimeDelta)s. Effective jump beyond uptime: \(detectedJump)s).")
                print("StoreManager: Details - CurrentTime: \(Date(timeIntervalSince1970:currentTime)), PrevWallTime: \(Date(timeIntervalSince1970:validReferenceTimestamp)), CurrentUptime: \(currentUptime), PrevUptime: \(previousUptime)")
                print("StoreManager: Details - minAdvanceForPenalty: \(minAdvanceForPenalty), timeCheatTolerance: \(timeCheatTolerance)")

                let penaltyMultiplier = self.forwardTimeCheatPenaltyFactor > 1.0 ? (self.forwardTimeCheatPenaltyFactor - 1.0) : 0.0
                let penaltyAmount = detectedJump * penaltyMultiplier // Penalty is on the actual "jumped" time

                let newTargetUnlockTimeWithPenalty = currentTime + self.boosterCooldown + penaltyAmount
                self.nextFreeBoosterDate = Date(timeIntervalSince1970: newTargetUnlockTimeWithPenalty)
                
                print("StoreManager: Forward cheat penalized. Jumped \(detectedJump)s. Penalty factor (\(penaltyMultiplier)) applied to jump -> \(penaltyAmount)s added. Next booster at \(self.nextFreeBoosterDate!) (Cooldown: \(self.boosterCooldown)s).")
                
                didApplyForwardPenalty = true
            } else {
                print("StoreManager: No forward time cheat detected or jump (\(detectedJump)s) is insignificant (threshold: \(minAdvanceForPenalty + timeCheatTolerance)s).")
            }
        } else { // Reboot detected (currentUptime < previousUptime)
            print("StoreManager: Device reboot detected (currentUptime: \(currentUptime)s < previousUptime: \(previousUptime)s). Skipping forward time cheat detection for this session.")
            // No forward penalty applied in this case. Timers will proceed based on currentTime.
        }

        // --- Update Timestamps & Finalize Booster Date if no penalty applied ---
        UserDefaults.standard.set(currentTime, forKey: lastValidatedTimestampKey)
        UserDefaults.standard.set(currentUptime, forKey: lastValidatedUptimeKey)

        // If no penalty was applied by the forward cheat detection,
        // and if the booster date was not set by init or backward cheat,
        // ensure it's correctly reflecting availability.
        if !didApplyForwardPenalty { // MODIFIED: Check this flag
            if self.nextFreeBoosterDate == nil {
                // This case should ideally be covered by init, but as a fallback.
                self.nextFreeBoosterDate = Date(timeIntervalSince1970: currentTime) // Booster available immediately
                print("StoreManager: Set nextFreeBoosterDate to current time as it was nil and no penalty applied.")
            } else if currentTime >= self.nextFreeBoosterDate!.timeIntervalSince1970 {
                // If current time is past the unlock date, it means the booster is available.
                // The date is already in the past or now, indicating availability. No change needed to make it "more" available.
                // Claiming the booster will then set the new cooldown.
                print("StoreManager: Booster is available (current time \(Date(timeIntervalSince1970:currentTime)) is past nextFreeBoosterDate \(self.nextFreeBoosterDate!)).")
            } else {
                // Booster is still cooling down, and no cheat detected or penalty applied to change it.
                print("StoreManager: Booster is still on cooldown until \(self.nextFreeBoosterDate!). No cheat detected impacting timer.")
            }
        }
    }

    func useBooster() {
        print("StoreManager: useBooster called. Current boosters: \(boosters)")
        if boosters > 0 {
            boosters -= 1
            
            if boosters == 0 {
                // Si c'était le dernier booster, et qu'il n'y a pas déjà un minuteur en cours
                // (ce qui ne devrait pas arriver si la logique est correcte, mais par sécurité)
                if self.nextFreeBoosterDate == nil || self.nextFreeBoosterDate! <= Date() {
                    print("StoreManager: Last booster used. Starting new timer.")
                    startNewBoosterTimer(from: Date().timeIntervalSince1970)
                } else {
                     print("StoreManager: Last booster used, but a timer is already active for \(self.nextFreeBoosterDate!). Not starting a new one.")
                }
            }
            print("StoreManager: Booster used. Remaining: \(boosters)")
        } else {
            print("StoreManager: Attempted to use booster, but none available.")
        }
    }

    private func startNewBoosterTimer(from startTime: TimeInterval) {
        let newTargetUnlockTime = startTime + boosterCooldown
        self.nextFreeBoosterDate = Date(timeIntervalSince1970: newTargetUnlockTime)
        self.referenceDeviceTimestampWhenTimerSet = startTime // L'heure actuelle est la nouvelle référence
        
        print("StoreManager: 🕒 Started new booster timer. Next at: \(self.nextFreeBoosterDate!), Reference time: \(Date(timeIntervalSince1970: startTime)).")
        // NotificationManager.shared.scheduleBoosterNotification(for: self.nextFreeBoosterDate!)
    }
}
