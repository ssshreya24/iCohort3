import UIKit

class MainTabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupTabBar()
    }

    private func setupTabs() {
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

        // Announcements
                let announcements = AnnouncementsViewController(nibName: "AnnouncementViewController", bundle: nil)
                let annNav = UINavigationController(rootViewController: announcements)
                annNav.tabBarItem = UITabBarItem(title: "Updates",
                                                 image: UIImage(systemName: "megaphone.fill"),
                                                 tag: 1)

                viewControllers = [homeNav, annNav]
                selectedIndex = 0
            }

    private func setupTabBar() {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = .systemBackground
            
            // Configure item appearance
            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.iconColor = .systemGray
            itemAppearance.selected.iconColor = .systemBlue
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
            
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance
            
            tabBar.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = appearance
            }
        }
    }
