import UIKit

class MentorMainTabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupTabBar()
    }

    private func setupTabs() {
        // Home (Student Dashboard)
        let dashSB = UIStoryboard(name: "MDashboard", bundle: nil)
        let homeVC = dashSB.instantiateViewController(withIdentifier: "MDashboardVC") as! MDashboardViewController
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(title: "Home",
                                          image: UIImage(systemName: "house.fill"),
                                          tag: 0)

        // 📅 Calendar
        let calendarSB = UIStoryboard(name: "MCalendar", bundle: nil)
               let calendarVC = calendarSB.instantiateViewController(withIdentifier: "MCalendarVC") as! MCalendarViewController
               let calNav = UINavigationController(rootViewController: calendarVC)
               calNav.tabBarItem = UITabBarItem(
                   title: "Calendar",
                   image: UIImage(systemName: "calendar"),
                   tag: 1
               )
        // Announcements
                let announcements = MentorAnnouncementsViewController(nibName: "MentorAnnouncementsViewController", bundle: nil)
                let annNav = UINavigationController(rootViewController: announcements)
                annNav.tabBarItem = UITabBarItem(title: "Announcements",
                                                 image: UIImage(systemName: "megaphone.fill"),
                                                 tag: 1)

                viewControllers = [homeNav,calNav,annNav]
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
