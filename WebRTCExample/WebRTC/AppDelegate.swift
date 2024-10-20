//
//  AppDelegate.swift
//  WebRTC
//
//  Created by Baran Karaoğuz on 18.10.2024.
//

import UIKit
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = true
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: CallViewController(viewModel: CallViewModel(transitionData: .init())))
        window?.makeKeyAndVisible()
        return true
    }
    
}

