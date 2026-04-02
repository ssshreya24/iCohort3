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
        homeNav.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),              // unselected
            selectedImage: UIImage(systemName: "house.fill")  // selected
        )
        
        // Calendar
        let calendarSB = UIStoryboard(name: "MCalendar", bundle: nil)
        let calendarVC = calendarSB.instantiateViewController(withIdentifier: "MCalendarVC") as! MCalendarViewController
        let calNav = UINavigationController(rootViewController: calendarVC)
        calNav.tabBarItem = UITabBarItem(
            title: "Calendar",
            image: UIImage(systemName: "calendar"),                 // unselected
            selectedImage: UIImage(systemName: "calendar.circle.fill") // selected (icon looks better)
        )
        
        // Announcements
        let announcements = MentorAnnouncementsViewController(nibName: "MentorAnnouncementsViewController", bundle: nil)
        let annNav = UINavigationController(rootViewController: announcements)
        annNav.tabBarItem = UITabBarItem(
            title: "Announcement",
            image: UIImage(systemName: "megaphone"),              // unselected
            selectedImage: UIImage(systemName: "megaphone.fill")  // selected
        )
        
        viewControllers = [homeNav, calNav, annNav]
        selectedIndex = 0
    }
    
    private func setupTabBar() {
        AppTheme.configureTabBarAppearance(tabBar)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        AppTheme.configureTabBarAppearance(tabBar)
    }
}
