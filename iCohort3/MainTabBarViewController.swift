//
//  MainTabBarViewController.swift
//  iCohort3
//
//  Created by user@51 on 09/11/25.
//

import UIKit

class MainTabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()

        // Do any additional setup after loading the view.
    }
    
    private func setupTabs() {
        
            //title = "Home"
            //tabBarItem = UITabBarItem(title: "Home",
                                                //image: UIImage(systemName: "house.fill"),
                                                //tag: 0)
        
            //tile = "Activities"
            //tabBarItem = UITabBarItem(title: "Activities",
                                  //image: UIImage(systemName: "calendar.fill"),
                                  //tag: 1)
        
            let announcementVC = AnnouncementsViewController(nibName: "AnnouncementViewController", bundle: nil)
            announcementVC.title = "Announcements"
            announcementVC.tabBarItem = UITabBarItem(title: "Updates",
                                                     image: UIImage(systemName: "horn.blast.fill"),
                                                     tag: 1)

            
            viewControllers = [
                UINavigationController(rootViewController: announcementVC)
            ]
        }
    }
