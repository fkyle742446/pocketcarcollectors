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
        // Force le mode clair pour toute l'application
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = .light
            }
        }
        
        // Configuration supplémentaire pour s'assurer que le mode clair est appliqué
        let appearance = UIView.appearance()
        appearance.overrideUserInterfaceStyle = .light
        
        // Force également le mode clair pour la navigation
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
                    // Load products when app starts
                    await iapManager.loadProducts()
                }
                .environmentObject(iapManager)
        }
    }
}
