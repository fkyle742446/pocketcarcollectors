import SwiftUI

struct ReferralView: View {
    @ObservedObject var referralManager: ReferralManager
    @ObservedObject var storeManager: StoreManager
    @ObservedObject var collectionManager: CollectionManager

    @Environment(\.dismiss) private var dismiss

    @State private var referralCodeInput: String = ""
    @State private var showingReferralAlert: Bool = false
    @State private var referralAlertTitle: String = ""
    @State private var referralAlertMessage: String = ""
    
    @State private var showReferralBoosterOpening: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Referral Code:")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        HStack {
                            Text(referralManager.userReferralCode)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                            Button {
                                UIPasteboard.general.string = referralManager.userReferralCode
                                referralAlertTitle = "Copied!"
                                referralAlertMessage = "Your referral code \(referralManager.userReferralCode) has been copied."
                                showingReferralAlert = true
                                HapticManager.shared.impact(style: .light)
                            } label: {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter a Friend's Code:")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            TextField("Enter code", text: $referralCodeInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                                .padding(.vertical, 4)
                            
                            Button("Submit") {
                                submitReferralCode()
                                HapticManager.shared.impact(style: .medium)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(referralCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Referral Rewards")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)

                        ProgressView(value: Double(referralManager.enteredCodesCount), total: Double(referralManager.maxCodesForRewards)) {
                             EmptyView()
                        } currentValueLabel: {
                            Text("Friends Referred: \(referralManager.enteredCodesCount) / \(referralManager.maxCodesForRewards)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                        
                        Text("Refer others to earn boosters! The more friends you refer, the more rewards you unlock.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.bottom, 3)

                        if !referralManager.claimableRewards.isEmpty {
                            Text("Claimable Rewards:")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .padding(.top, 3)
                            ForEach(referralManager.claimableRewards, id: \.codesRequired) { reward in
                                Button {
                                    referralManager.claimReward(reward, storeManager: storeManager)
                                } label: {
                                    HStack {
                                        Image(systemName: "gift.fill")
                                        Text("Claim \(reward.description)")
                                        Spacer()
                                        Text("(\(reward.codesRequired) codes)")
                                            .font(.caption)
                                    }
                                    .padding(10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green.opacity(0.9))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .shadow(radius: 3)
                                }
                            }
                        }
                        
                        Text("Reward Tiers:")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .padding(.top, 5)
                        ForEach(referralManager.rewardMilestones, id: \.codesRequired) { milestone in
                            HStack(spacing: 8) {
                                Image(systemName: referralManager.claimedRewardTiers.contains(milestone.codesRequired) ? "checkmark.circle.fill" : (referralManager.enteredCodesCount >= milestone.codesRequired ? "gift.fill" : "circle"))
                                    .foregroundColor(referralManager.claimedRewardTiers.contains(milestone.codesRequired) ? .green : (referralManager.enteredCodesCount >= milestone.codesRequired ? .orange : .gray))
                                    .font(.headline)
                                Text("\(milestone.description) at \(milestone.codesRequired) codes")
                                Spacer()
                            }
                            .font(.caption)
                            .padding(.vertical, 2)
                            .opacity(referralManager.claimedRewardTiers.contains(milestone.codesRequired) ? 0.6 : 1.0)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                    VStack(alignment: .center, spacing: 10) {
                        Text("Your Referral Boosters")
                            .font(.system(size: 17, weight: .bold))
                        
                        Image(BoosterContext.referral.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 130, height: 170)
                            .shadow(color: storeManager.referralBoostersToOpen > 0 ? .green.opacity(0.5) : .gray.opacity(0.3), radius: 8)
                            .opacity(storeManager.referralBoostersToOpen > 0 ? 1.0 : 0.6)
                            .onTapGesture {
                                if storeManager.referralBoostersToOpen > 0 {
                                    showReferralBoosterOpening = true
                                    HapticManager.shared.impact(style: .medium)
                                }
                            }
                        
                        if storeManager.referralBoostersToOpen > 0 {
                            Text("You have \(storeManager.referralBoostersToOpen) referral booster\(storeManager.referralBoostersToOpen > 1 ? "s" : "") to open!")
                                .font(.subheadline)
                        } else {
                            Text("You have no referral boosters yet.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("Refer friends to unlock these exclusive boosters!")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button {
                            if storeManager.referralBoostersToOpen > 0 {
                                showReferralBoosterOpening = true
                                HapticManager.shared.impact(style: .heavy)
                            }
                        } label: {
                            Text("Open Referral Booster")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(storeManager.referralBoostersToOpen > 0 ? Color.green.opacity(0.9) : Color.gray.opacity(0.7))
                                .cornerRadius(10)
                                .shadow(radius: 3)
                        }
                        .disabled(storeManager.referralBoostersToOpen == 0)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    Spacer(minLength: 15)

                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .background(Color(UIColor.systemGray6).ignoresSafeArea())
            .navigationTitle("Referral Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert(referralAlertTitle, isPresented: $showingReferralAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(referralAlertMessage)
            }
            .fullScreenCover(isPresented: $showReferralBoosterOpening) {
                BoosterOpeningView(
                    collectionManager: collectionManager,
                    context: .referral
                )
            }
        }
    }

    private func submitReferralCode() {
        let result = referralManager.enterReferralCode(referralCodeInput, storeManager: storeManager)
        switch result {
        case .success:
            referralAlertTitle = "Code Accepted!"
            referralAlertMessage = "Referral code '\(referralCodeInput.uppercased())' successfully entered. Check your rewards!"
            AudioManager.shared.playSound(named: "referral_code_success")
        case .invalidCode:
            referralAlertTitle = "Invalid Code"
            referralAlertMessage = "The code '\(referralCodeInput.uppercased())' is not a valid referral code."
            AudioManager.shared.playSound(named: "error_sound")
        case .alreadyEntered:
            referralAlertTitle = "Already Entered"
            referralAlertMessage = "You have already entered the code '\(referralCodeInput.uppercased())'."
        case .ownCode:
            referralAlertTitle = "That's Your Code!"
            referralAlertMessage = "You cannot enter your own referral code."
        case .unknownError:
            referralAlertTitle = "Error"
            referralAlertMessage = "An unknown error occurred. Please try again."
        }
        showingReferralAlert = true
        referralCodeInput = ""
    }
}

struct ReferralView_Previews: PreviewProvider {
    static var previews: some View {
        let previewStoreManager = StoreManager.shared
        previewStoreManager.referralBoostersToOpen = 2
        
        let previewCollectionManager = CollectionManager()
        
        return ReferralView(
            referralManager: ReferralManager.shared,
            storeManager: previewStoreManager,
            collectionManager: previewCollectionManager
        )
    }
}
