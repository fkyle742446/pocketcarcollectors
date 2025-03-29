import SwiftUI

struct BoosterTimerView: View {
    @StateObject private var store = StoreManager.shared
    @State private var showingAlert = false
    
    var body: some View {
        VStack {
            Text(store.currentTimeString)
                .onTapGesture {
                    showingAlert = true
                }
        }
        .alert("Use Points", isPresented: $showingAlert) {
            Button("Use \(store.hoursNeeded) Points") {
                store.skipWaitingTime()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You need \(store.hoursNeeded) points to skip this timer.")
        }
    }
}
