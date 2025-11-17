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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        let otpVC = OTPViewController(nibName: "OTPViewController", bundle: nil)
        
        // Check if we have a navigation controller
        if let nav = navigationController {
            // Push onto navigation stack for proper back navigation
            nav.pushViewController(otpVC, animated: true)
        } else {
            // Fallback to modal presentation
            otpVC.modalPresentationStyle = .fullScreen
            present(otpVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        let signUpVC = SignUpViewController(nibName: "SignUpViewController", bundle: nil)
        
        if let nav = navigationController {
            nav.pushViewController(signUpVC, animated: true)
        } else {
            signUpVC.modalPresentationStyle = .fullScreen
            present(signUpVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func togglePasswordVisibility(_ sender: UIButton) {
        passwordTextField.isSecureTextEntry.toggle()
        let imageName = passwordTextField.isSecureTextEntry ? "eye.slash.fill" : "eye.fill"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
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
        print("Login back button tapped, nav:", navigationController as Any)
        
        // Try to pop from navigation stack
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
            return
        }
        
        // If we're at root or no nav controller, go back to UserSelection
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let userSelection = storyboard.instantiateViewController(withIdentifier: "UserSelectionVC") as? UserSelectionViewController {
            let navRoot = UINavigationController(rootViewController: userSelection)
            navRoot.modalPresentationStyle = .fullScreen
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                window.rootViewController = navRoot
                window.makeKeyAndVisible()
            } else if let window = view.window {
                window.rootViewController = navRoot
                window.makeKeyAndVisible()
            } else {
                present(navRoot, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        let loginVC = LoginViewController(nibName: "LoginViewController", bundle: nil)
        loginVC.modalPresentationStyle = .fullScreen
        present(loginVC, animated: true, completion: nil)
    }
    
    func handleLoginSuccess() {
        let tab = MainTabBarViewController()
        
        let win = view.window ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        
        guard let window = win else { return }
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = tab
        }
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
        
        // Basic validation
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            print("Email or password cannot be empty")
            return
        }
        
        // Example: simulate login success
        print("Login successful for user:", email)
        
        // Optionally store remember-me preference
        if rememberMeButton.isSelected {
            print("Remember Me is checked. Saving credentials/state.")
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
        }
        
        handleLoginSuccess()
    }
}
