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
        homeNav.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),              // unselected
            selectedImage: UIImage(systemName: "house.fill")  // selected
        )

        // Calendar
        let calendarSB = UIStoryboard(name: "SCalendar", bundle: nil)
        let calendarVC = calendarSB.instantiateViewController(withIdentifier: "SCalendarVC") as! SCalendarViewController
        let calNav = UINavigationController(rootViewController: calendarVC)
        calNav.tabBarItem = UITabBarItem(
            title: "Calendar",
            image: UIImage(systemName: "calendar"),                  // unselected
            selectedImage: UIImage(systemName: "calendar.circle.fill") // selected
        )

        // Updates
        let announcements = AnnouncementsViewController(nibName: "AnnouncementViewController", bundle: nil)
        let annNav = UINavigationController(rootViewController: announcements)
        annNav.tabBarItem = UITabBarItem(
            title: "Updates",
            image: UIImage(systemName: "megaphone"),              // unselected
            selectedImage: UIImage(systemName: "megaphone.fill")  // selected
        )

        viewControllers = [homeNav, calNav, annNav]
        selectedIndex = 0
    }

    private func setupTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .systemBackground

        let itemAppearance = UITabBarItemAppearance()

        // Unselected
        itemAppearance.normal.iconColor = UIColor.black.withAlphaComponent(0.4)
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.black.withAlphaComponent(0.4)
        ]

        // Selected
        itemAppearance.selected.iconColor = .black
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.black
        ]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
}
