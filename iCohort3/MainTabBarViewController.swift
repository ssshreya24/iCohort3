import UIKit

class MainTabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        styleTabBar()
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

            private func styleTabBar() {
                // Modern appearance with blur
                let appearance = UITabBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
                appearance.shadowColor = .clear

                tabBar.standardAppearance = appearance
                tabBar.scrollEdgeAppearance = appearance

                tabBar.layer.cornerRadius = 22
                tabBar.layer.masksToBounds = true
                tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

                // Add subtle shadow for floating effect
                tabBar.layer.shadowColor = UIColor.black.cgColor
                tabBar.layer.shadowOpacity = 0.1
                tabBar.layer.shadowOffset = CGSize(width: 0, height: -3)
                tabBar.layer.shadowRadius = 12
                tabBar.layer.masksToBounds = false

                tabBar.tintColor = .black
                tabBar.unselectedItemTintColor = .gray
            }

            override func viewDidLayoutSubviews() {
                super.viewDidLayoutSubviews()

                guard let windowScene = view.window?.windowScene else { return }
                let screenBounds = windowScene.screen.bounds
                let bottomInset = view.safeAreaInsets.bottom

                let tabBarHeight = tabBar.frame.height + 6
                tabBar.frame = CGRect(
                    x: 20,
                    y: screenBounds.height - (tabBarHeight + bottomInset + 10),
                    width: screenBounds.width - 40,
                    height: tabBarHeight
                )
            }
        }
