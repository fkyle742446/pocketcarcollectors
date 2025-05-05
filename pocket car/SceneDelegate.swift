import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        print("🔵 Scene will connect")
        
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()
        
        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
        
        // Handle deep link if app was launched via URL
        if let urlContext = connectionOptions.urlContexts.first {
            print("🔵 Deep link on launch: \(urlContext.url)")
            ContentView.handleDeepLink(urlContext.url)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("🔵 Scene received URL")
        guard let urlContext = URLContexts.first else { return }
        print("🔵 Deep link while running: \(urlContext.url)")
        ContentView.handleDeepLink(urlContext.url)
    }
}
