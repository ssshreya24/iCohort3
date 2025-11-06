//
//  LoginViewController.swift
//  Login Screen
//
//  Created by user@51 on 03/11/25.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!

    @IBOutlet weak var containerView2: UIView!
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var passwordVisibilityToggle: UIButton!
    
    @IBOutlet weak var signInButton: UIButton!

    @IBOutlet weak var rememberMeButton: UIButton!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        // Do any additional setup after loading the view.
    }
    
    func setupUI() {

            passwordTextField.isSecureTextEntry = true

 
            passwordVisibilityToggle.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
            
  
            rememberMeButton.isSelected = false
            rememberMeButton.setImage(UIImage(systemName: "square"), for: .normal)
            rememberMeButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
            
            signInButton.layer.cornerRadius = 20
            signInButton.layer.masksToBounds = true

            emailTextField.layer.cornerRadius = 0
            emailTextField.layer.masksToBounds = true

            passwordTextField.layer.cornerRadius = 0
            passwordTextField.layer.masksToBounds = true

        containerView.layer.cornerRadius = 23
        containerView.layer.masksToBounds = true
        
        containerView2.layer.cornerRadius = 23
        containerView2.layer.masksToBounds = true
        }
    
    @IBAction func signInTapped(_ sender: UIButton) {
        print("Sign In button tapped")
            
            // Example: simple validation
            guard let email = emailTextField.text, !email.isEmpty,
                  let password = passwordTextField.text, !password.isEmpty else {
                print("Email or password cannot be empty")
                return
            }

            // Navigate to Dashboard
            let storyboard = UIStoryboard(name: "SDashboard", bundle: nil)
            if let dashboardVC = storyboard.instantiateViewController(withIdentifier: "SDashboardVC") as? SDashboardViewController {
                dashboardVC.modalPresentationStyle = .fullScreen
                navigationController?.pushViewController(dashboardVC, animated: true)
            }

            if rememberMeButton.isSelected {
                print("Remember Me is checked. Save credentials/state.")
            }
    }
    
    
    @IBAction func togglePasswordVisibility(_ sender: UIButton) {
        passwordTextField.isSecureTextEntry.toggle()


        let imageName = passwordTextField.isSecureTextEntry ? "eye.slash.fill" : "eye.fill"
        (sender as AnyObject).setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    
    @IBAction func rememberMeTapped(_ sender: UIButton) {

        sender.isSelected.toggle()
        
        if sender.isSelected {
            print("Remember Me is now CHECKED.")
        } else {
            print("Remember Me is now UNCHECKED.")
        }
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        if navigationController?.popViewController(animated: true) == nil {
                    print("Already at the root screen.")
        }
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
