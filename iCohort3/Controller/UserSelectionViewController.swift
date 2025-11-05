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
        
        // Do any additional setup after loading the view.
    }
    
    func setupCardStyling() {
            
            let views = [studentCardView, facultyCardView]
            
            for card in views {
                guard let card = card else { continue }
                card.layer.cornerRadius = 16
                card.layer.shadowColor = UIColor.black.cgColor
                card.layer.shadowOpacity = 0.1 // Light, subtle shadow
                card.layer.shadowOffset = CGSize(width: 0, height: 4)
                card.layer.shadowRadius = 8
                card.layer.masksToBounds = false
            }
        }

    
    
    func navigateToLogin() {
        guard let loginVC = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "SLoginVC") as? LoginViewController else {
            print("ERROR: Navigation Failed! Check if 'LoginViewController' has 'Storyboard ID' set to 'LoginVC' in the Identity Inspector.")
            return
        }

        navigationController?.pushViewController(loginVC, animated: true)
    }

            
            // --- Actions ---
            
    @IBAction func studentCardTapped(_ sender: UIButton) {
                print("Student card selected. Proceeding to student-specific flow.")
                navigateToLogin()
            }
            
            
    @IBAction func facultyCardTapped(_ sender: UIButton) {
                print("Faculty card selected. Proceeding to faculty-specific flow.")
                navigateToLogin()
            }
            

            
            
            /*
             // MARK: - Navigation
             
             // In a storyboard-based application, you will often want to do a little preparation before navigation
             override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
             // Get the new view controller using segue.destination.
             // Pass the selected object to the new view controller.
             }
             */
            
        
    
}
