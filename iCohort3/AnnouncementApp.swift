//
//  AnnouncementApp.swift
//  iCohort3
//
//  Created by user@51 on 08/11/25.
//

//
//  AppDelegate.swift
//  iCohort3
//


import UIKit

@main
class AnnouncementApp: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        let rootVC = AnnouncementsViewController(nibName: "AnnouncementViewController", bundle: nil)
        window?.rootViewController = UINavigationController(rootViewController: rootVC)
        window?.makeKeyAndVisible()
        return true
    }
}

