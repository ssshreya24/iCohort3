// MainTabBarViewController.swift
import UIKit

class MainTabBarViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Home (Student Dashboard)
        let dashSB = UIStoryboard(name: "SDashboard", bundle: nil)
                let homeVC = dashSB.instantiateViewController(withIdentifier: "SDashboardVC") as! SDashboardViewController
                let homeNav = UINavigationController(rootViewController: homeVC)
                homeNav.tabBarItem = UITabBarItem(title: "Home",
                                                  image: UIImage(systemName: "house.fill"),
                                                  tag: 0)


//        // Calendar
//        let calendar = CalendarViewController(nibName: "CalendarViewController", bundle: nil)
//        let calNav = UINavigationController(rootViewController: calendar)
//        calNav.tabBarItem = UITabBarItem(title: "Calendar",
//                                         image: UIImage(systemName: "calendar"),
//                                         tag: 1)

        // Updates / Announcements
        let announcements = AnnouncementsViewController(nibName: "AnnouncementViewController", bundle: nil)
        let annNav = UINavigationController(rootViewController: announcements)
        annNav.tabBarItem = UITabBarItem(title: "Updates",
                                         image: UIImage(systemName: "megaphone.fill"),
                                         tag: 1)

        viewControllers = [homeNav, annNav]
        selectedIndex = 0   // start on Home

        tabBar.layer.cornerRadius = 18
        tabBar.layer.masksToBounds = true
        tabBar.isTranslucent = true
        tabBar.tintColor = .black
        tabBar.unselectedItemTintColor = .darkGray
    }
}
