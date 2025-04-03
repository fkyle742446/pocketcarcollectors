//
//  pocket_carApp.swift
//  pocket car
//
//  Created by florian on 08/12/2024.
//

import SwiftUI
import StoreKit

@main
struct pocket_carApp: App {
    @StateObject private var iapManager = IAPManager.shared
    
    init() {
        // Force light mode for the entire application
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = .light
            }
        }
        
        // Additional configuration to ensure light mode is applied
        let appearance = UIView.appearance()
        appearance.overrideUserInterfaceStyle = .light
        
        // Force light mode for navigation
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().overrideUserInterfaceStyle = .light
    }
    
    var body: some Scene {
        WindowGroup {
            pocket_car.SplashScreenView()
                .preferredColorScheme(.light)
                .task {
                    await iapManager.loadProducts()
                }
                .environmentObject(iapManager)
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
