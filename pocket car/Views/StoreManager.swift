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
    
    private init() {
        print("StoreManager: Initializing...")
        self.boosters = UserDefaults.standard.integer(forKey: "boosters")
        
        if !UserDefaults.standard.bool(forKey: "initialBoostersGiven_v2") { // Changed key
            self.boosters = 4
            UserDefaults.standard.set(true, forKey: "initialBoostersGiven_v2")
            // UserDefaults.standard.set(self.boosters, forKey: "boosters") // Déjà fait par le didSet de boosters
            print("StoreManager: Given initial 4 boosters.")
        }
        
        loadAndValidateBoosterTimer()
        
        // S'abonner aux notifications de cycle de vie de l'application
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        print("StoreManager: Initialized. Boosters: \(self.boosters), NextFreeDate: \(String(describing: self.nextFreeBoosterDate)), ReferenceDeviceTS: \(String(describing: self.referenceDeviceTimestampWhenTimerSet))")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func appWillEnterForeground() {
        print("StoreManager: App will enter foreground. Checking and validating booster timer.")
        loadAndValidateBoosterTimer()
    }

    func loadAndValidateBoosterTimer() {
        print("StoreManager: loadAndValidateBoosterTimer called.")
        let currentTime = Date().timeIntervalSince1970
        
        guard let savedNextBoosterTimestamp = UserDefaults.standard.object(forKey: "nextBoosterTimestamp_v2") as? TimeInterval else {
            // Pas de minuteur enregistré. Si 0 boosters, démarrer un nouveau.
            if self.boosters == 0 {
                print("StoreManager: No saved timer and 0 boosters. Starting new timer.")
                startNewBoosterTimer(from: currentTime)
            } else {
                print("StoreManager: No saved timer, but has \(self.boosters) boosters. No timer needed.")
                self.nextFreeBoosterDate = nil
                self.referenceDeviceTimestampWhenTimerSet = nil
            }
            return
        }

        var targetUnlockTimestamp = savedNextBoosterTimestamp
        var currentReferenceDeviceTimestamp = self.referenceDeviceTimestampWhenTimerSet

        // Si referenceDeviceTimestampWhenTimerSet n'existe pas (migration ou ancien état)
        // On l'initialise de manière conservatrice.
        if currentReferenceDeviceTimestamp == nil {
            currentReferenceDeviceTimestamp = targetUnlockTimestamp - boosterCooldown
            self.referenceDeviceTimestampWhenTimerSet = currentReferenceDeviceTimestamp
            print("StoreManager: referenceDeviceTimestampWhenTimerSet was nil. Initialized to \(Date(timeIntervalSince1970: currentReferenceDeviceTimestamp!)).")
        }
        
        guard let validReferenceTimestamp = currentReferenceDeviceTimestamp else {
            // Devrait pas arriver si on l'a initialisé au-dessus, mais sécurité
            print("StoreManager: Error - validReferenceTimestamp is nil after attempted initialization. Resetting timer.")
            startNewBoosterTimer(from: currentTime)
            return
        }

        print("StoreManager: Current time: \(Date(timeIntervalSince1970: currentTime)) (\(currentTime))")
        print("StoreManager: Saved target unlock: \(Date(timeIntervalSince1970: targetUnlockTimestamp)) (\(targetUnlockTimestamp))")
        print("StoreManager: Reference device time when timer set: \(Date(timeIntervalSince1970: validReferenceTimestamp)) (\(validReferenceTimestamp))")

        // Détection et correction de triche par recul du temps
        if currentTime < validReferenceTimestamp - timeCheatTolerance {
            let timeShiftDetected = validReferenceTimestamp - currentTime
            print("StoreManager: ⚠️ Time cheat detected (clock moved backwards by \(timeShiftDetected)s).")
            targetUnlockTimestamp += timeShiftDetected // Repousser la cible d'autant
            self.referenceDeviceTimestampWhenTimerSet = currentTime // Mettre à jour la référence à l'heure actuelle (trichée)
            
            // Sauvegarder la nouvelle date cible mise à jour à cause de la triche
            self.nextFreeBoosterDate = Date(timeIntervalSince1970: targetUnlockTimestamp)
            // La notification devra être replanifiée avec cette nouvelle date
            NotificationManager.shared.scheduleBoosterNotification(for: Date(timeIntervalSince1970: targetUnlockTimestamp))
            print("StoreManager: Adjusted target unlock to \(Date(timeIntervalSince1970: targetUnlockTimestamp)) due to time cheat.")
            // Pas besoin de vérifier pour un booster gratuit maintenant, car le temps a été reculé.
            return
        }
        
        // MODIFIE: forward time cheat detection pour n'utiliser minAdvanceForPenalty
        // (pénalité si l'utilisateur avance l'heure de plus de 30 minutes)
        if currentTime > (validReferenceTimestamp + minAdvanceForPenalty + timeCheatTolerance) {
            let skippedTimeBeyondNormalAdvance = currentTime - (validReferenceTimestamp + minAdvanceForPenalty)
            
            print("StoreManager: ⚠️ Forward time cheat detected (more than 30 min ahead). Clock advanced by \(skippedTimeBeyondNormalAdvance + minAdvanceForPenalty)s (Current: \(currentTime), Ref: \(validReferenceTimestamp), MinAdvance: \(minAdvanceForPenalty), Tolerance: \(timeCheatTolerance)).")

            // Appliquer la même pénalité proportionnelle que précédemment
            let penaltyMultiplier = self.forwardTimeCheatPenaltyFactor > 1.0 ? (self.forwardTimeCheatPenaltyFactor - 1.0) : 0.0
            let penaltyAmount = skippedTimeBeyondNormalAdvance * penaltyMultiplier

            // Nouvel unlock : 6h à partir du moment triché + pénalité
            let newTargetUnlockTimeWithPenalty = currentTime + self.boosterCooldown + penaltyAmount

            self.nextFreeBoosterDate = Date(timeIntervalSince1970: newTargetUnlockTimeWithPenalty)
            self.referenceDeviceTimestampWhenTimerSet = currentTime // On repart de la nouvelle "base"
            NotificationManager.shared.scheduleBoosterNotification(for: self.nextFreeBoosterDate!)
            print("StoreManager: Forward cheat penalized. Next booster at \(self.nextFreeBoosterDate!) (raw timestamp: \(newTargetUnlockTimeWithPenalty)). Cheated time: \(Date(timeIntervalSince1970: currentTime)), Cooldown: \(self.boosterCooldown)s, Additional Penalty: \(penaltyAmount)s.")
            return
        }

        // Mettre à jour la référence si le temps a avancé normalement (et pas de triche détectée)
        // Ceci est important si l'application est restée fermée longtemps.
        // On ne le fait que si on n'est pas en train de donner un booster,
        // car donner un booster va démarrer un *nouveau* minuteur avec sa propre référence.
        if currentTime < targetUnlockTimestamp {
             self.referenceDeviceTimestampWhenTimerSet = currentTime
        }


        // Vérification normale pour un booster gratuit
        if currentTime >= targetUnlockTimestamp {
            print("StoreManager: Free booster condition met. CurrentTime (\(currentTime)) >= TargetTime (\(targetUnlockTimestamp))")
            self.boosters += 1
            print("StoreManager: Booster added. Total boosters: \(self.boosters).")
            // Démarrer un nouveau minuteur pour le prochain booster, à partir de MAINTENANT
            startNewBoosterTimer(from: currentTime)
        } else {
            // Le minuteur est toujours en cours et aucune triche détectée, s'assurer que l'UI est à jour
            self.nextFreeBoosterDate = Date(timeIntervalSince1970: targetUnlockTimestamp)
            print("StoreManager: Timer still active. Next booster at \(self.nextFreeBoosterDate!).")
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
        NotificationManager.shared.scheduleBoosterNotification(for: self.nextFreeBoosterDate!)
    }
}
