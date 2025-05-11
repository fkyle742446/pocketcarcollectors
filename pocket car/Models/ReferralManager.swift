import Foundation
import Combine

struct ReferralReward {
    let codesRequired: Int
    let boostersAwarded: Int 
    let description: String 
}

class ReferralManager: ObservableObject {
    static let shared = ReferralManager()

    private let allPossibleReferralCodes: [String] = [
        "POCKETAUTO001", "CARMASTER002", "SPEEDDEMON003", "GARAGEKING004", "COLLECTOR005",
        "TURBOCHARGE006", "NITROBOOST007", "DRIFTKING008", "RACE CHAMP009", "VINTAGERIDE010",
        "MUSCLECAR011", "SUPERCAR012", "EXOTICWHEELS013", "CUSTOMBUILD014", "SHOWSTOPPER015",
        "ROADTRIP016", "HIGHWAYSTAR017", "CITYCRUISER018", "OFFROADX019", "TUNERLIFE020",
        "GEARHEAD021", "AUTOENTHUSIAST022", "PISTONPOWER023", "ENGINE ROAR024", "FASTLANE025",
        "CLASSICCARS026", "MODERNRIDES027", "FUTUREFLEET028", "DREAMGARAGE029", "TOPGEAR030",
        "GRANDPRIX031", "LEMANSLEGEND032", "INDYWINNER033", "MONACOSTAR034", "SILVERSTONE035",
        "NURBURGRING036", "FORMULAONE037", "RALLYCROSS038", "DRAGRACE039", "STREETKING040",
        "LUXURY CARS041", "SPORTSCOUPE042", "CONVERTIBLE043", "HATCHBACKHERO044", "SEDAllNSTYLE045",
        "SUVCOMMANDER046", "TRUCKZILLA047", "VANLIFEPRO048", "MINICOMPACT049", "BIGWHEELS050",
        "SHINYCHROME051", "MATTEFINISH052", "CARBONFIBER053", "AEROKIT054", "SPOILERALERT055",
        "NEONLIGHTS056", "UNDERGLOW057", "SOUNDSYSTEM058", "CUSTOMPAINT059", "RACINGSTRIPES060",
        "ALLOYRIMS061", "PERFORMANCETIRES062", "BRAKEUPGRADE063", "SUSPENSIONTECH064", "EXHAUSTNOTE065",
        "COLDAIRINTAKE066", "ECUFLASH067", "DYNOTUNE068", "TRACKDAY069", "AUTOCROSS070",
        "CARMEET071", "CRUISE NIGHT072", "GARAGESQUAD073", "CLUBPOCKET074", "AUTOCODE075",
        "VEHICLEVIP076", "MOTOCODE077", "CARKEY078", "IGNITIONGO079", "DRIVEFAST080",
        "PARKMASTER081", "STEERINGPRO082", "CLUTCHCONTROL083", "THROTTLEUP084", "RPMREDLINE085",
        "CHECKEREDFLAG086", "PODIUMFINISH087", "TROPHYCASE088", "GOLDMEDAL089", "CHAMPIONSHIP090",
        "RARECOLLECT091", "LEGENDSTATUS092", "MYTHICMOTOR093", "EPICDRIVE094", "ULTIMATECAR095",
        "PCCREWARD096", "FLORIANDEV097", "BESTGAME098", "PLAYERONE099", "HIDDEN GEM100"
    ] 

    @Published var userReferralCode: String {
        didSet {
            if oldValue != userReferralCode || !UserDefaults.standard.dictionaryRepresentation().keys.contains("userReferralCodeKey") {
                UserDefaults.standard.set(userReferralCode, forKey: "userReferralCodeKey")
            }
        }
    }

    @Published var enteredCodesCount: Int = 0 {
        didSet {
            if oldValue != enteredCodesCount || !UserDefaults.standard.dictionaryRepresentation().keys.contains("enteredReferralCodesCountKey") {
                 UserDefaults.standard.set(enteredCodesCount, forKey: "enteredReferralCodesCountKey")
            }
            updateClaimableRewards()
        }
    }
    @Published private(set) var successfullyEnteredCodes: Set<String> {
        didSet {
            if oldValue != successfullyEnteredCodes || !UserDefaults.standard.dictionaryRepresentation().keys.contains("successfullyEnteredReferralCodesKey") {
                UserDefaults.standard.set(Array(successfullyEnteredCodes), forKey: "successfullyEnteredReferralCodesKey")
            }
            if self.enteredCodesCount != successfullyEnteredCodes.count {
                self.enteredCodesCount = successfullyEnteredCodes.count
            }
        }
    }
    
    @Published private(set) var claimedRewardTiers: Set<Int> {
        didSet {
            if oldValue != claimedRewardTiers || !UserDefaults.standard.dictionaryRepresentation().keys.contains("claimedReferralRewardTiersKey") {
                UserDefaults.standard.set(Array(claimedRewardTiers), forKey: "claimedReferralRewardTiersKey")
            }
            updateClaimableRewards()
        }
    }
    @Published private(set) var claimableRewards: [ReferralReward] = []

    let rewardMilestones: [ReferralReward] = [
        ReferralReward(codesRequired: 1, boostersAwarded: 1, description: "1 Referral Booster"),
        ReferralReward(codesRequired: 3, boostersAwarded: 2, description: "2 Referral Boosters"),
        ReferralReward(codesRequired: 5, boostersAwarded: 3, description: "3 Referral Boosters"),
        ReferralReward(codesRequired: 10, boostersAwarded: 5, description: "5 Referral Boosters")
    ]

    private init() {
        let initialUserCode: String
        if let savedCode = UserDefaults.standard.string(forKey: "userReferralCodeKey"),
           allPossibleReferralCodes.contains(savedCode) { 
            initialUserCode = savedCode
        } else {
            initialUserCode = allPossibleReferralCodes.randomElement() ?? "ERRORCODE000" 
            UserDefaults.standard.set(initialUserCode, forKey: "userReferralCodeKey")
        }
        self.userReferralCode = initialUserCode

        let savedEnteredCodesArray = UserDefaults.standard.array(forKey: "successfullyEnteredReferralCodesKey") as? [String] ?? []
        
        var tempSuccessfullyEnteredCodes = Set<String>()
        for code in savedEnteredCodesArray {
            if self.allPossibleReferralCodes.contains(code) { 
                tempSuccessfullyEnteredCodes.insert(code)
            }
        }
        self.successfullyEnteredCodes = tempSuccessfullyEnteredCodes
        
        let savedClaimedTiersArray = UserDefaults.standard.array(forKey: "claimedReferralRewardTiersKey") as? [Int] ?? []
        self.claimedRewardTiers = Set(savedClaimedTiersArray)
        
        let initialEnteredCount = self.successfullyEnteredCodes.count
        self.enteredCodesCount = initialEnteredCount

        updateClaimableRewards()

        print("ReferralManager initialized. User code: \(userReferralCode). Entered: \(enteredCodesCount)")
        print("Total possible referral codes: \(allPossibleReferralCodes.count)")
    }

    private func updateClaimableRewards() {
        claimableRewards = rewardMilestones.filter { milestone in
            enteredCodesCount >= milestone.codesRequired && !claimedRewardTiers.contains(milestone.codesRequired)
        }
    }

    enum CodeEntryResult {
        case success
        case invalidCode
        case alreadyEntered
        case ownCode
        case unknownError 
    }

    func enterReferralCode(_ code: String, storeManager: StoreManager) -> CodeEntryResult {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard normalizedCode != userReferralCode else {
            return .ownCode
        }
        guard allPossibleReferralCodes.contains(normalizedCode) else {
            return .invalidCode
        }
        guard !successfullyEnteredCodes.contains(normalizedCode) else {
            return .alreadyEntered
        }

        successfullyEnteredCodes.insert(normalizedCode) 
        print("Referral code \(normalizedCode) successfully entered. Total: \(enteredCodesCount)")
        return .success
    }

    func claimReward(_ reward: ReferralReward, storeManager: StoreManager) {
        guard enteredCodesCount >= reward.codesRequired, !claimedRewardTiers.contains(reward.codesRequired) else {
            print("Error: Reward already claimed or not eligible.")
            return
        }
        
        storeManager.referralBoostersToOpen += reward.boostersAwarded
        claimedRewardTiers.insert(reward.codesRequired) 
        
        print("Claimed referral reward: \(reward.description) for \(reward.codesRequired) codes. Referral Boosters added: \(reward.boostersAwarded). Total referral boosters: \(storeManager.referralBoostersToOpen)")
        AudioManager.shared.playSound(named: "reward_claim_success") 
        HapticManager.shared.impact(style: .medium) 
    }
    
    var maxCodesForRewards: Int {
        rewardMilestones.map { $0.codesRequired }.max() ?? 1
    }
}
