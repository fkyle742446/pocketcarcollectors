//
//  pocket_carApp.swift
//  pocket car
//
//  Created by florian on 08/12/2024.
//



import SwiftUI

@main
struct pocket_carApp: App {
    init() {
        // Force l'application en mode clair
        UIWindow.appearance().overrideUserInterfaceStyle = .light
    }
    
    var body: some Scene {
        WindowGroup {
            pocket_car.SplashScreenView()
        }
    }
}
