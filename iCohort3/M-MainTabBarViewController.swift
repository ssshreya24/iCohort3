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
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .systemBackground
        
        let itemAppearance = UITabBarItemAppearance()
        
        // Unselected
        itemAppearance.normal.iconColor = .black.withAlphaComponent(0.4)
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
