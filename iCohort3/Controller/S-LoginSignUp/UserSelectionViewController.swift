//
//  UserSelectionViewController.swift
//  Login Screen
//
//  Created by user@51 on 03/11/25.
//

import UIKit

class UserSelectionViewController: UIViewController {
    
    @IBOutlet weak var studentCardView: UIView!
    @IBOutlet weak var facultyCardView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCardStyling()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func setupCardStyling() {
        let views = [studentCardView, facultyCardView]
        
        for card in views {
            guard let card = card else { continue }
            card.layer.cornerRadius = 16
            card.layer.shadowColor = UIColor.black.cgColor
            card.layer.shadowOpacity = 0.1
            card.layer.shadowOffset = CGSize(width: 0, height: 4)
            card.layer.shadowRadius = 8
            card.layer.masksToBounds = false
        }
    }
    
    // ✅ Navigate to Student Login (SLoginVC)
    private func navigateToStudentLogin() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = sb.instantiateViewController(withIdentifier: "SLoginVC") as? LoginViewController else {
            print("ERROR: Couldn't instantiate LoginViewController with Storyboard ID 'SLoginVC'.")
            return
        }
        
        if let nav = navigationController {
            nav.pushViewController(loginVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: loginVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
    
    // ✅ Navigate to Faculty/Mentor Login (MLoginVC)
    private func navigateToFacultyLogin() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = sb.instantiateViewController(withIdentifier: "MLoginVC") as? MLoginSignUpViewController else {
            print("ERROR: Couldn't instantiate MLoginViewController with Storyboard ID 'MLoginVC'.")
            return
        }
        
        if let nav = navigationController {
            nav.pushViewController(loginVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: loginVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func studentCardTapped(_ sender: UIButton) {
        print("Student card selected. Proceeding to student login.")
        navigateToStudentLogin()
    }
    
    @IBAction func facultyCardTapped(_ sender: UIButton) {
        print("Faculty card selected. Proceeding to faculty login.")
        navigateToFacultyLogin()
    }
}
